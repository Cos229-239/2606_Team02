using UnrealBuildTool;
using System.Collections.Generic;

public class MysticGroveTarget : TargetRules
{
	public MysticGroveTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V6;
		ExtraModuleNames.Add("MysticGrove");
	}
}
