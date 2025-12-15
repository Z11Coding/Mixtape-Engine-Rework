package backend.window.os;

#if (mac && CROSSPLATFORM)
@:cppFileCode('
#include <sys/sysctl.h>
#include <sys/mount.h>
#include <mach/mach.h>
#include <mach/mach_host.h>
')
class Mac {
	@:functionCode('
		int mib [] = { CTL_HW, HW_MEMSIZE };
		int64_t value = 0;
		size_t length = sizeof(value);

		if(-1 == sysctl(mib, 2, &value, &length, NULL, 0))
			return -1; // An error occurred

		return value / 1024 / 1024;
	')
	public static function getTotalRam():Float
	{
		return 0;
	}

	@:functionCode('
		vm_size_t page_size;
		mach_port_t mach_port = mach_host_self();
		vm_statistics_data_t vm_stat;
		mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);

		host_page_size(mach_port, &page_size);
		host_statistics(mach_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);

		int64_t free_memory = (vm_stat.free_count + vm_stat.inactive_count) * page_size;
		return free_memory / 1024 / 1024; // Convert to MB
	')
	public static function getAvailableRam():Float
	{
		return 0;
	}

	// Get macOS version
	public static function getMacOSVersion():String
	{
		try {
			var process = new sys.io.Process("sw_vers", ["-productVersion"]);
			var version = process.stdout.readAll().toString().trim();
			process.close();
			return version;
		} catch (e:Dynamic) {
			trace("Failed to get macOS version: " + e);
			return "Unknown";
		}
	}

	// Check if a command exists
	public static function hasCommand(command:String):Bool
	{
		try {
			var result = Sys.command('which $command > /dev/null 2>&1');
			return result == 0;
		} catch (e:Dynamic) {
			return false;
		}
	}

	// Get system architecture
	@:functionCode('
		int mib[] = { CTL_HW, HW_MACHINE };
		size_t size = 0;
		sysctl(mib, 2, NULL, &size, NULL, 0);

		char *machine = (char*)malloc(size);
		sysctl(mib, 2, machine, &size, NULL, 0);

		String result = String(machine);
		free(machine);
		return result;
	')
	public static function getArchitecture():String
	{
		return "Unknown";
	}
}
#end
