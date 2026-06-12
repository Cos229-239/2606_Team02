using UnrealBuildTool;
using System.Collections.Generic;

public class MysticGroveEditorTarget : TargetRules
{
	public MysticGroveEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V6;
		ExtraModuleNames.Add("MysticGrove");
	}
}
