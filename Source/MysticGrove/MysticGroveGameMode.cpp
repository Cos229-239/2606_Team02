#include "MysticGroveGameMode.h"

#include "MysticGrovePlayerController.h"
#include "MysticHud.h"

AMysticGroveGameMode::AMysticGroveGameMode()
{
	PlayerControllerClass = AMysticGrovePlayerController::StaticClass();
	HUDClass = AMysticHud::StaticClass();
	DefaultPawnClass = nullptr;
}
