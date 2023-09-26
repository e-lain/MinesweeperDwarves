extends Node

const WINDOWS_OS_NAMES = ["Windows","UWP"]
const MACOS_OS_NAMES = ["macOS"]
const LINUX_OS_NAMES = ["Linux"]
const BSD_OS_NAMES = ["FreeBSD", "NetBSD", "OpenBSD","BSD"]
const MOBILE_OS_NAMES = ["Android","iOS"]
const DESKTOP_OS_NAMES = WINDOWS_OS_NAMES + MACOS_OS_NAMES + LINUX_OS_NAMES + BSD_OS_NAMES
const WEB_OS_NAMES = ["HTML5"]

var OS_NAME = OS.get_name()
var __isDesktop = OS_NAME in DESKTOP_OS_NAMES
var __isMobile = OS_NAME in MOBILE_OS_NAMES
var __isWeb = OS_NAME in WEB_OS_NAMES

func get_os_name():
	return OS_NAME
func isDesktop():
	return __isDesktop
func isMobile():
	return __isMobile
	
func isWeb():
	return __isWeb
