-- Example Dynamic Song Generation Script
-- This script demonstrates programmatic section selection for dynamic songs
-- Place in: example_mods/Dynamic-Song-Example/scripts/

local currentDifficulty = ""
local playerAccuracy = 0
local songProgress = 0

function onCreate()
    -- Called when the song starts
    currentDifficulty = getProperty('songDifficulty')

    -- Log that we're using dynamic generation
    debugPrint('Dynamic Song Script: Starting with difficulty ' .. currentDifficulty)
end

function onUpdate(elapsed)
    -- Track player performance for adaptive difficulty
    playerAccuracy = getProperty('ratingPercent')
    songProgress = getProperty('songPercent')
end

-- This function is called by the Dynamic Song Manager when generating sections
function generateSectionSequence(config)
    local sections = {}

    -- Always start with intro
    table.insert(sections, "intro")

    -- Determine verse difficulty based on song difficulty and player performance
    local verseDifficulty = "normal" -- default

    if currentDifficulty == "easy" or (playerAccuracy and playerAccuracy < 70) then
        verseDifficulty = "easy"
    elseif currentDifficulty == "hard" or (playerAccuracy and playerAccuracy > 90) then
        verseDifficulty = "hard"
    end

    -- Add verse with determined difficulty
    table.insert(sections, "verse_" .. verseDifficulty)

    -- Add chorus
    table.insert(sections, "chorus")

    -- Add another verse (same difficulty)
    table.insert(sections, "verse_" .. verseDifficulty)

    -- Add chorus again
    table.insert(sections, "chorus")

    -- Randomly choose between bridge or solo for variety
    local randomChoice = getRandomInt(1, 2)
    if randomChoice == 1 then
        table.insert(sections, "bridge")
        debugPrint('Dynamic Song: Selected bridge section')
    else
        table.insert(sections, "solo")
        debugPrint('Dynamic Song: Selected solo section')
    end

    -- Final chorus
    table.insert(sections, "chorus")

    -- Always end with outro
    table.insert(sections, "outro")

    debugPrint('Dynamic Song: Generated sequence with ' .. #sections .. ' sections')
    debugPrint('Dynamic Song: Verse difficulty: ' .. verseDifficulty)

    return sections
end

-- Alternative generation function for performance-based adaptation
function generateAdaptiveSections(config)
    local sections = {}

    table.insert(sections, "intro")

    -- Performance-based section selection
    if playerAccuracy and playerAccuracy > 95 then
        -- Player is doing extremely well - give them a challenge
        table.insert(sections, "verse_hard")
        table.insert(sections, "solo") -- More challenging solo
        table.insert(sections, "verse_hard")
        debugPrint('Dynamic Song: High performance - using hard sections')
    elseif playerAccuracy and playerAccuracy < 60 then
        -- Player is struggling - ease up
        table.insert(sections, "verse_easy")
        table.insert(sections, "bridge") -- Calmer bridge
        table.insert(sections, "verse_easy")
        debugPrint('Dynamic Song: Low performance - using easy sections')
    else
        -- Normal performance
        table.insert(sections, "verse_normal")
        table.insert(sections, "chorus")
        table.insert(sections, "verse_normal")
        debugPrint('Dynamic Song: Normal performance - using standard sections')
    end

    table.insert(sections, "outro")

    return sections
end

-- Custom randomization with weighted choices
function generateWeightedSections(config)
    local sections = {}

    table.insert(sections, "intro")

    -- Weighted random selection for middle sections
    local weights = {
        verse_easy = 20,
        verse_normal = 50,
        verse_hard = 30
    }

    -- Add two verses with weighted random selection
    for i = 1, 2 do
        local selectedVerse = getWeightedRandom(weights)
        table.insert(sections, selectedVerse)
        table.insert(sections, "chorus")
    end

    -- 70% chance for bridge, 30% for solo
    local bridgeOrSolo = getRandomInt(1, 100)
    if bridgeOrSolo <= 70 then
        table.insert(sections, "bridge")
    else
        table.insert(sections, "solo")
    end

    table.insert(sections, "outro")

    return sections
end

-- Utility function for weighted random selection
function getWeightedRandom(weights)
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end

    local random = getRandomInt(1, totalWeight)
    local currentWeight = 0

    for option, weight in pairs(weights) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return option
        end
    end

    -- Fallback
    return "verse_normal"
end
