import {
  createConnection,
  TextDocuments,
  Diagnostic,
  DiagnosticSeverity,
  ProposedFeatures,
  InitializeParams,
  DidChangeConfigurationNotification,
  CompletionItem,
  CompletionItemKind,
  TextDocumentPositionParams,
  TextDocumentSyncKind,
  InitializeResult,
  Hover,
  MarkupKind
} from 'vscode-languageserver/node';

import {
  TextDocument
} from 'vscode-languageserver-textdocument';

import { YScriptTokenizer } from './tokenizer';
import { YScriptParser } from './parser';
import { YScriptValidator } from './validator';
import { YScriptCompletion } from './completion';
import { YScriptHover } from './hover';

// Create a connection for the server, using Node's IPC as a transport.
// Also include all preview / proposed LSP features.
const connection = createConnection(ProposedFeatures.all);

// Create a simple text document manager.
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

// YScript language components
const tokenizer = new YScriptTokenizer();
const parser = new YScriptParser();
const validator = new YScriptValidator();
const completion = new YScriptCompletion();
const hover = new YScriptHover();

connection.onInitialize((params: InitializeParams) => {
  const capabilities = params.capabilities;

  // Does the client support the `workspace/configuration` request?
  // If not, we fall back using global settings.
  hasConfigurationCapability = !!(
    capabilities.workspace && !!capabilities.workspace.configuration
  );
  hasWorkspaceFolderCapability = !!(
    capabilities.workspace && !!capabilities.workspace.workspaceFolders
  );
  hasDiagnosticRelatedInformationCapability = !!(
    capabilities.textDocument &&
    capabilities.textDocument.publishDiagnostics &&
    capabilities.textDocument.publishDiagnostics.relatedInformation
  );

  const result: InitializeResult = {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      // Tell the client that this server supports code completion.
      completionProvider: {
        resolveProvider: true,
        triggerCharacters: ['.', ':', ' ']
      },
      hoverProvider: true
    }
  };
  if (hasWorkspaceFolderCapability) {
    result.capabilities.workspace = {
      workspaceFolders: {
        supported: true
      }
    };
  }
  return result;
});

connection.onInitialized(() => {
  if (hasConfigurationCapability) {
    // Register for all configuration changes.
    connection.client.register(DidChangeConfigurationNotification.type, undefined);
  }
  if (hasWorkspaceFolderCapability) {
    connection.workspace.onDidChangeWorkspaceFolders(_event => {
      connection.console.log('Workspace folder change event received.');
    });
  }
});

// The example settings
interface YScriptSettings {
  validate: {
    enable: boolean;
  };
  completion: {
    enable: boolean;
  };
  hover: {
    enable: boolean;
  };
  haxe: {
    integration: boolean;
  };
  trace: {
    server: string;
  };
}

// The global settings, used when the `workspace/configuration` request is not supported by the client.
// Please note that this is not the case when using this server with the client provided in this example
// but could happen with other clients.
const defaultSettings: YScriptSettings = {
  validate: { enable: true },
  completion: { enable: true },
  hover: { enable: true },
  haxe: { integration: true },
  trace: { server: 'off' }
};
let globalSettings: YScriptSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings: Map<string, Thenable<YScriptSettings>> = new Map();

connection.onDidChangeConfiguration(change => {
  if (hasConfigurationCapability) {
    // Reset all cached document settings
    documentSettings.clear();
  } else {
    globalSettings = <YScriptSettings>(
      (change.settings.yscript || defaultSettings)
    );
  }

  // Revalidate all open text documents
  documents.all().forEach(validateTextDocument);
});

function getDocumentSettings(resource: string): Thenable<YScriptSettings> {
  if (!hasConfigurationCapability) {
    return Promise.resolve(globalSettings);
  }
  let result = documentSettings.get(resource);
  if (!result) {
    result = connection.workspace.getConfiguration({
      scopeUri: resource,
      section: 'yscript'
    });
    documentSettings.set(resource, result);
  }
  return result;
}

// Only keep settings for open documents
documents.onDidClose(e => {
  documentSettings.delete(e.document.uri);
});

// The content of a text document has changed. This event is emitted
// when the text document first opened or when its content has changed.
documents.onDidChangeContent(change => {
  validateTextDocument(change.document);
});

async function validateTextDocument(textDocument: TextDocument): Promise<void> {
  // In this simple example we get the settings for every validate run.
  const settings = await getDocumentSettings(textDocument.uri);

  if (!settings.validate.enable) {
    return;
  }

  const text = textDocument.getText();
  const diagnostics: Diagnostic[] = [];

  try {
    // Tokenize the document
    const tokens = tokenizer.tokenize(text);

    // Parse the tokens into an AST
    const ast = parser.parse(tokens);

    // Validate the AST
    const validationErrors = validator.validate(ast);

    // Convert validation errors to diagnostics
    for (const error of validationErrors) {
      const diagnostic: Diagnostic = {
        severity: DiagnosticSeverity.Error,
        range: {
          start: textDocument.positionAt(error.start),
          end: textDocument.positionAt(error.end)
        },
        message: error.message,
        source: 'yscript'
      };

      if (hasDiagnosticRelatedInformationCapability) {
        diagnostic.relatedInformation = [
          {
            location: {
              uri: textDocument.uri,
              range: Object.assign({}, diagnostic.range)
            },
            message: error.details || 'YScript parsing error'
          }
        ];
      }
      diagnostics.push(diagnostic);
    }
  } catch (error) {
    // Handle parser errors
    const diagnostic: Diagnostic = {
      severity: DiagnosticSeverity.Error,
      range: {
        start: textDocument.positionAt(0),
        end: textDocument.positionAt(text.length)
      },
      message: `YScript parsing failed: ${error}`,
      source: 'yscript'
    };
    diagnostics.push(diagnostic);
  }

  // Send the computed diagnostics to VS Code.
  connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
}

// This handler provides the initial list of the completion items.
connection.onCompletion(
  async (_textDocumentPosition: TextDocumentPositionParams): Promise<CompletionItem[]> => {
    const document = documents.get(_textDocumentPosition.textDocument.uri);
    if (!document) {
      return [];
    }

    const settings = await getDocumentSettings(_textDocumentPosition.textDocument.uri);
    if (!settings.completion.enable) {
      return [];
    }

    const text = document.getText();
    const offset = document.offsetAt(_textDocumentPosition.position);

    try {
      const tokens = tokenizer.tokenize(text);
      const ast = parser.parse(tokens);
      return completion.getCompletionItems(ast, offset, _textDocumentPosition.position);
    } catch (error) {
      return [];
    }
  }
);

// This handler resolves additional information for the item selected in
// the completion list.
connection.onCompletionResolve(
  (item: CompletionItem): CompletionItem => {
    return completion.resolveCompletionItem(item);
  }
);

// This handler provides hover information
connection.onHover(
  async (_textDocumentPosition: TextDocumentPositionParams): Promise<Hover | null> => {
    const document = documents.get(_textDocumentPosition.textDocument.uri);
    if (!document) {
      return null;
    }

    const settings = await getDocumentSettings(_textDocumentPosition.textDocument.uri);
    if (!settings.hover.enable) {
      return null;
    }

    const text = document.getText();
    const offset = document.offsetAt(_textDocumentPosition.position);

    try {
      const tokens = tokenizer.tokenize(text);
      const ast = parser.parse(tokens);
      return hover.getHoverInfo(ast, offset, _textDocumentPosition.position);
    } catch (error) {
      return null;
    }
  }
);

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();
