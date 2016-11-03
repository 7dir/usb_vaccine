@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION 2 GOTO cmd_ext_ok
ENDLOCAL 
echo Requires Windows 2000 or later.
GOTO EOF
exit 1;
exit 
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
REM 'usb_vaccine.cmd' version 3 beta zh-TW (2016-11-03)
REM Copyright (C) 2013-2015 Kang-Che Sung <explorer09 @ gmail.com>

REM This program is free software; you can redistribute it and/or
REM modify it under the terms of the GNU Lesser General Public
REM License as published by the Free Software Foundation; either
REM version 2.1 of the License, or (at your option) any later version.

REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
REM Lesser General Public License for more details.

REM You should have received a copy of the GNU Lesser General Public
REM License along with this program. If not, see
REM <http://www.gnu.org/licenses/>.
REM ---------------------------------------------------------------------------
REM CONSTANTS

REM User's default options for commands. Reset.
SET COPYCMD=
SET DIRCMD=
REM Disable user override.
SET CD=
SET ERRORLEVEL=

SET HKLM_SFT=HKLM\SOFTWARE
SET HKLM_CLS=%HKLM_SFT%\Classes
SET HKLM_SFT_WOW=%HKLM_SFT%\Wow6432Node

SET "CMD_SUBKEY=Microsoft\Command Processor"
SET "INF_MAP_SUBKEY=Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET "EXPLORER_SUBKEY=Microsoft\Windows\CurrentVersion\Explorer"
SET "ADVANCED_SUBKEY=%EXPLORER_SUBKEY%\Advanced"
SET "SHELL_ICON_SUBKEY=%EXPLORER_SUBKEY%\Shell Icons"

REM BIG5 �\�\�\���D workaround
SET "BIG5_A15E=�^"
SET "BIG5_A65E=�^"
SET "BIG5_AE7C=�|"
SET "BIG5_B77C=�|"

REM Files to keep. The whitelist.
SET KEEP_SYMLINK_FILES=
FOR %%i IN (
) DO (
    SET KEEP_SYMLINK_FILES=!KEEP_SYMLINK_FILES! %%i
)
SET KEEP_HS_ATTRIB_FILES=
FOR %%i IN (
"ibmbio.com" "ibmdos.com" "IO.SYS" "IO.DOS" "WINBOOT.SYS" "JO.SYS" "MSDOS.SYS"
"MSDOS.DOS" "MSDOS.BAK" "MSDOS.W40" "MSDOS.---" "@oldbios.ui" "@oldbdos.ui"
"COMMAND.COM" "COMMAND.DOS" "AUTOEXEC.DOS" "CONFIG.DOS" "OS2BOOT" "OS2LDR"
"OS2LDR.MSG" "OS2KRNL" "OS2DUMP" "OS2VER" "OS2LOGO" "EA DATA. SF" "WP ROOT. SF"
"Nowhere\" "386SPART.PAR" "pagefile.sys" "swapfile.sys" "hiberfil.sys"
"SSPARTSS.ADD" "STACKER.BIN" "STACKER.INI" "STACVOL.DSK" "DBLSPACE.BIN"
"DRVSPACE.BIN" "DBLSPACE.INI" "DRVSPACE.INI" "DBLSPACE.000" "DRVSPACE.000"
"FAILSAFE.DRV\" "@DLWATCH.DAT" "Recycled\" "RECYCLER\" "$Recycle.Bin\"
"boot.ini" "Boot.BAK" "bootfont.bin" "bootsect.dos" "NTDETECT.COM" "ntldr"
"@oldboot.ui" "SUHDLOG.DAT" "SUHDLOG.---" "arcldr.exe" "arcsetup.exe" "Boot\"
"bootmgr" "BOOTNXT" "BOOTSECT.BAK" "BOOTTGT" "BOOTLOG.TXT" "BOOTLOG.PRV"
"DETLOG.TXT" "DETLOG.OLD" "NETLOG.TXT" "SETUPLOG.TXT" "SETUPLOG.OLD"
"system.1st" "UNINSTAL.INI" "WINLFN.INI" "System Volume Information\"
"cmdcons\" "cmldr" "Recovery\" "SECURITY.BIN" "VIDEOROM.BIN" "EBD.SYS"
) DO (
    SET KEEP_HS_ATTRIB_FILES=!KEEP_HS_ATTRIB_FILES! %%i
)
SET KEEP_H_ATTRIB_FILES=
FOR %%i IN (
"ibmbio.com" "ibmdos.com" "MSDOS.---" "logo.sys" "@command.ui" "autoexec.bat"
"@AUTOEXE.UI" "config.sys" "@CONFIG.UI" "OS2LDR" "OS2KRNL" "SENTRY\" "Boot.BAK"
"SUHDLOG.DAT" "SUHDLOG.---" "BOOTLOG.TXT" "BOOTLOG.PRV" "SETUPLOG.TXT"
"SETUPLOG.OLD" "ASD.LOG" "CLASSES.1ST" "system.1st" "W95UNDO.DAT" "W95UNDO.INI"
"WINUNDO.DAT" "WINUNDO.INI" "W98UNDO.DAT" "W98UNDO.INI" "W9XUNDO.DAT"
"W9XUNDO.INI" "$INPLACE.~TR\" "$WINDOWS.~Q\" "$Windows.~BT\" "_Restore\"
"$WINRE_BACKUP_PARTITION.MARKER" "DOS00I.400" "DOS01L.400" "ProgramData\"
"MSOCache\"
) DO (
    SET KEEP_H_ATTRIB_FILES=!KEEP_H_ATTRIB_FILES! %%i
)
SET KEEP_S_ATTRIB_FILES=
FOR %%i IN (
"PCTRACKR.DEL" "boot.ini" "BOOTSECT.BAK"
) DO (
    SET KEEP_S_ATTRIB_FILES=!KEEP_S_ATTRIB_FILES! %%i
)
SET KEEP_EXECUTE_FILES=
FOR %%i IN (
"ibmbio.com" "ibmdos.com" "COMMAND.COM" "autoexec.bat" "STARTUP.CMD"
"STACKER.EXE" "NTDETECT.COM" "arcldr.exe" "arcsetup.exe"
) DO (
    SET KEEP_EXECUTE_FILES=!KEEP_EXECUTE_FILES! %%i
)

REM ---------------------------------------------------------------------------
REM MAIN

SET g_reg_bak=
SET g_sids=

REM Needed by restart routine. SHIFT will change %*.
SET "args=%*"

:main_parse_options
SET "arg1=%~1"
IF "!arg1!"=="" GOTO main_sanity_test
    IF "!arg1!"=="/?" SET opt_help=1
    IF "!arg1!"=="-?" SET opt_help=1
    IF "!arg1!"=="--help" SET opt_help=1
    IF "!arg1:~0,5!"=="--no-" (
        FOR %%i IN (restart reg_bak inf_mapping mkdir) DO (
            IF "!arg1:-=_!"=="__no_%%i" SET "opt_%%i=SKIP"
        )
    )
    IF "!arg1:~0,7!"=="--skip-" (
        FOR %%i IN (
            cmd_autorun mountpoints known_ext pif_ext scf_icon scrap_ext
        ) DO (
            IF "!arg1:-=_!"=="__skip_%%i" SET "opt_%%i=SKIP"
        )
    )
    IF "!arg1:~0,12!"=="--all-users-" (
        FOR %%i IN (cmd_autorun known_ext reassoc) DO (
            IF "!arg1:-=_!"=="__all_users_%%i" SET "opt_%%i=ALL_USERS"
        )
    )
    IF "!arg1:~0,6!"=="--fix-" (
        FOR %%i IN (exe_ext shortcut_icon file_icon) DO (
            IF "!arg1:-=_!"=="__fix_%%i" SET "opt_%%i=FIX"
        )
    )
    IF "!arg1!"=="--always-exe-ext" SET "opt_exe_ext=ALWAYS"
    IF "!arg1:~0,7!"=="--keep-" (
        FOR %%i IN (
            symlinks attrib shortcuts folder_exe autorun_inf desktop_ini
        ) DO (
            IF "!arg1:-=_!"=="__keep_%%i" SET "opt_%%i=SKIP"
        )
    )
    IF "!arg1:~0,13!"=="--move-subdir" (
        IF "!arg1:~13,1!"=="=" (
            REM User quotes the argument so that '=' is included.
            SET opt_move_subdir=!arg1:~14!
        ) ELSE (
            REM '=' becomes delimiter. Get the next argument.
            SET "opt_move_subdir=%~2"
            SHIFT /1
        )
        SET opt_move_subdir=!opt_move_subdir:^"=!
        SET opt_move_subdir=!opt_move_subdir:/=\!
    )
    REM %0 is needed by restart routine. Don't touch.
    SHIFT /1
GOTO main_parse_options

:main_sanity_test
IF "!opt_help!"=="1" SET opt_restart=SKIP
IF "!opt_reg_bak!"=="SKIP" SET g_reg_bak=FAIL

REM Humbly quit when we get a Unix 'find' utility. We won't bother with
REM 'findstr' or (ported) 'grep'.
find . -prune >NUL 2>NUL && GOTO main_find_error
ECHO X | find "X" >NUL 2>NUL || GOTO main_find_error

IF "!opt_move_subdir!"=="" SET opt_move_subdir=\MALWARE
REM Technically we can't check for every possibility of valid path without
REM actually 'mkdir' with it, but we may filter out common path attacks.
REM Note: There may be false positives with a multi-byte encoded path.
REM (Code point 0xXX5C. GBK, Big5, Shift_JIS, EUC-KR all vulnerable.)
IF "!opt_move_subdir:~0,2!"=="\\" GOTO main_invalid_path
REM Windows 9x allows "\...\", "\....\" and so on for grandparent or any
REM ancestor directory. Thankfully it doesn't work anymore in NT.
ECHO "\!opt_move_subdir!\" | find "\..\" >NUL && GOTO main_invalid_path
ECHO "!opt_move_subdir!" | find "*" >NUL && GOTO main_invalid_path
ECHO "!opt_move_subdir!" | find "?" >NUL && GOTO main_invalid_path
FOR %%c IN (":" "<" ">" "|") DO (
    ECHO "!opt_move_subdir!" | find %%c >NUL && GOTO main_invalid_path
)

reg query "HKCU" >NUL 2>NUL || (
    ECHO.>&2
    ECHO *** ���~�G�L�k�ϥ� reg.exe �Ӧs�� Windows �n���I>&2
    ECHO.>&2
    ECHO �p�G�z�ϥ� Windows 2000�A�Цw�� Windows 2000 �䴩�u��C>&2
    ECHO �Ա��Ш� ^<https://support.microsoft.com/kb/301423^>�A�z�i�H�q���U���䴩�u��G>&2
    ECHO ^<https://www.microsoft.com/download/details.aspx?id=18614^>>&2
    IF "!opt_help!"=="1" GOTO main_help
    ECHO.>&2
    ECHO �Ҧ��n���ɤu�@�N!BIG5_B77C!�Q���L�C>&2
    GOTO main_all_drives
)

SET g_is_wow64=0
IF DEFINED PROCESSOR_ARCHITEW6432 (
    IF NOT "!opt_restart!"=="SKIP" GOTO main_restart_native
    SET g_is_wow64=1
    ECHO �`�N�G������ WoW64 ���������ҡC���}�����ӭn�b�@�~�t�ιw�]�� 64 �줸���R�O��Ķ��>&2
    ECHO �]cmd.exe!BIG5_A15E!�U����C>&2
)
SET has_wow64=0
reg query "%HKLM_SFT_WOW%" >NUL 2>NUL && SET has_wow64=1

:main_cmd_autorun
SET has_cmd_autorun=0
FOR %%k IN (%HKLM_SFT_WOW% %HKLM_SFT% HKCU\Software) DO (
    REM "reg query" outputs header lines even if key or value doesn't exist.
    reg query "%%k\%CMD_SUBKEY%" /v "AutoRun" >NUL 2>NUL && (
        IF NOT "!opt_restart!"=="SKIP" GOTO main_restart
        SET has_cmd_autorun=1
        REM Show user the AutoRun values along with error message below.
        REM Key name included in "reg query" output.
        IF "!g_is_wow64!!has_wow64!%%k"=="10%HKLM_SFT%" (
            ECHO �]���U�����X�� WoW64 ���w�V�����X�A������ڦW�٬�>&2
            ECHO   "%HKLM_SFT_WOW%\%CMD_SUBKEY%"!BIG5_A15E!>&2
        )
        IF NOT "!g_is_wow64!!has_wow64!%%k"=="11%HKLM_SFT%" (
            reg query "%%k\%CMD_SUBKEY%" /v "AutoRun" >&2
        )
    )
)
IF "!has_cmd_autorun!"=="1" (
    ECHO *** �`�N�G�b���T����ܤ��e�A�z���R�O��Ķ���]cmd.exe!BIG5_A15E!�w�g�۰ʰ���F�@�ǩR�O�A�o>&2
    ECHO     �ǩR�O�i�ର�c�N�{���C>&2
)
IF "!opt_help!"=="1" GOTO main_help
IF "!opt_cmd_autorun!"=="SKIP" GOTO main_inf_mapping
IF "!has_cmd_autorun!"=="1" (
    IF NOT "!opt_cmd_autorun!"=="ALL_USERS" (
        ECHO [cmd-autorun]
        ECHO ���F�w���ʪ���]�A�ڭ̱N�R���W���C�X�� "AutoRun" �n���ȡC
        ECHO �]�v�T�����P�ثe�ϥΪ̪��]�w�C���L�k�Q�_��C�Y�n�R���Ҧ��ϥΪ̪��]�w�A�Ы��w
        ECHO '--all-users-cmd-autorun' �ﶵ�C!BIG5_A15E!
        CALL :continue_prompt || GOTO main_inf_mapping
    )
    FOR %%k IN (%HKLM_SFT_WOW% %HKLM_SFT% HKCU\Software) DO (
        CALL :delete_reg_value "%%k" "%CMD_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)
IF "!opt_cmd_autorun!"=="ALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        CALL :delete_reg_value "HKU\%%~i\Software" "%CMD_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)

:main_inf_mapping
SET has_inf_mapping=1
reg query "%HKLM_SFT%\%INF_MAP_SUBKEY%" /ve 2>NUL | find /I "@" >NUL || (
    SET has_inf_mapping=0
    ECHO.>&2
    ECHO *** �M�I�G�z���q������ AutoRun �c�N�n�骺�����I>&2
)
ECHO.
ECHO ���{���i�H���U�z�����۰ʰ���]AutoRun!BIG5_A15E!�B�M�z�z�Ϻи̪� autorun.inf �ɮסB����
ECHO ��!BIG5_AE7C!����ܳQ���ê��ɮסC�o�ǰʧ@�_�� AutoRun �c�N�n�鰵�y�����ˮ`�C
ECHO ���{���u�ä�!BIG5_B77C!�v�����c�N�n�饻���A�ҥH����ΨӨ��N���r�n��C�Цw�ˤ@�M���r�n��
ECHO �ӫO�@�z���q���C
ECHO �p�G�z�ϥ� Windows 2000�BXP�BServer 2003�BVista �� Server 2008�A�ڭ̱j�P��ĳ�z
ECHO �w�˷L�n�� KB967715 �P KB971029 ��s�A���G��s�ץ��F AutoRun ��@�����Ρ]�Y�ϧ�
ECHO ��!BIG5_B77C!����Ҧ��� AutoRun!BIG5_A15E!�C
ECHO �Ш� ^<https://technet.microsoft.com/library/security/967940.aspx^>

REM Credit to Nick Brown for the solution to disable AutoRun. See:
REM http://archive.today/CpwOH
REM http://www.computerworld.com/article/2481506
REM Works with Windows 7 too, and I believe it's safer to disable ALL AutoRuns
REM in Windows 7 and above, rather than let go some devices.
REM Other references:
REM http://www.kb.cert.org/vuls/id/889747
REM https://www.us-cert.gov/ncas/alerts/TA09-020A
IF "!has_inf_mapping!"=="1" GOTO main_mountpoints
IF "!opt_inf_mapping!"=="SKIP" GOTO main_mountpoints
ECHO.
ECHO [inf-mapping]
ECHO ��z��J���СA�ηƹ��I�����о��ϥܮɡAWindows �b�w�]�U!BIG5_B77C!�۰ʰ���Y�ǵ{���]�q�`
ECHO �O�w�˵{��!BIG5_A15E!�C�쥻�O���Ѥ�K�A���o�ӡu�۰ʰ���v�]AutoRun!BIG5_A15E!�]�p�o�e���Q�c�N�n��
ECHO �Q�ΡA�b�ϥΪ̥��dı�����p�U�۰ʰ���C
ECHO �ڭ̱N�����Ҧ��۰ʰ���]AutoRun!BIG5_A15E!�A�ð��� Windows ��R���� autorun.inf �ɮסC��
ECHO �� AutoRun ����A�p�G�z�n�q���и̭��w�˩ΰ���n��A�z������ʶ}�Ҹ̭���
ECHO Setup.exe�C�o�ä��v�T���֡A�q�v���СA�� USB �˸m���۰ʼ���]AutoPlay!BIG5_A15E!�\��C
ECHO �]�o�O�����]�w�C!BIG5_A15E!
CALL :continue_prompt || GOTO main_mountpoints
CALL :backup_reg "%HKLM_SFT%" "%INF_MAP_SUBKEY%" /ve
reg add "%HKLM_SFT%\%INF_MAP_SUBKEY%" /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >NUL
IF ERRORLEVEL 1 (
    CALL :show_reg_write_error "IniFileMapping\autorun.inf"
) ELSE (
    CALL :delete_reg_key "%HKLM_SFT%" "DoesNotExist" "%HKLM_SFT%\DoesNotExist"
)
IF "!has_wow64!"=="1" (
    CALL :backup_reg "%HKLM_SFT_WOW%" "%INF_MAP_SUBKEY%" /ve
    reg add "%HKLM_SFT_WOW%\%INF_MAP_SUBKEY%" /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >NUL
    IF ERRORLEVEL 1 (
        CALL :show_reg_write_error "(WoW64) IniFileMapping\autorun.inf"
    ) ELSE (
        CALL :delete_reg_key "%HKLM_SFT_WOW%" "DoesNotExist" "(WoW64) %HKLM_SFT%\DoesNotExist"
    )
)

:main_mountpoints
IF "!opt_mountpoints!"=="SKIP" GOTO main_known_ext
REM "MountPoints" for Windows 2000, "MountPoints2" for Windows XP and later.
ECHO.
ECHO [mountpoints]
ECHO "MountPoints"�]�� "MountPoints2"!BIG5_A15E!�n�����X�� Windows �ɮ��`�ު� AutoRun �֨���
ECHO �ơA�b AutoRun ��������A�M�z���X�H�קK���e�˸m�� AutoRun �¯١C
ECHO �]�v�T�Ҧ��ϥΪ̪��]�w�C���L�k�Q�_��C!BIG5_A15E!
CALL :continue_prompt || GOTO main_known_ext
CALL :prepare_sids
FOR %%i IN (!g_sids!) DO (
    ECHO SID %%~i
    FOR %%k IN (MountPoints MountPoints2) DO (
        CALL :clean_reg_key "HKU\%%~i\Software" "%EXPLORER_SUBKEY%\%%k" "Explorer\%%k"
    )
)

:main_known_ext
IF "!opt_known_ext!"=="SKIP" GOTO main_exe_ext
REM The value shouldn't exist in HKLM and doesn't work there. Silently delete.
FOR %%k IN (%HKLM_SFT% %HKLM_SFT_WOW%) DO (
    reg delete "%%k\%ADVANCED_SUBKEY%" /v "HideFileExt" /f >NUL 2>NUL
)
IF NOT "!opt_known_ext!"=="ALL_USERS" (
    ECHO.
    ECHO [known-ext]
    ECHO Windows �w�]!BIG5_B77C!���äw���ɮ����������ɦW�A���O���ε{���i�H���ۭq���ϥܡA�b���ɦW
    ECHO �Q���ê��ɭԡA�c�N�{���i�H�Q�ιϥܨӰ��˦����q�ɮשθ�Ƨ��A�H���F�ϥΪ̥h�}��
    ECHO ���̡C
    ECHO �ڭ̱N�����u����x�v���u��Ƨ��ﶵ�v���u���äw���ɮ����������ɦW�v�A�ϱo�`�Ϊ�
    ECHO ���ɦW�]����!BIG5_AE7C!�~!BIG5_A15E!�û��Q��ܡC�ϥΪ̥i�H�z�L���ɦW�ӿ�{�ɮ׬O�_�������ɡ]�ӥB
    ECHO �i��!BIG5_A15E!�A�H�U���i���檺�ɮ������G
    ECHO     .com�]MS-DOS ���ε{��!BIG5_A15E!    .cmd�]Windows NT �R�O�}��!BIG5_A15E!
    ECHO     .exe�]���ε{��!BIG5_A15E!           .scr�]�ù��O�@�{��!BIG5_A15E!
    ECHO     .bat�]�妸�ɮ�!BIG5_A15E!
    ECHO �]�v�T�ثe�ϥΪ̪��]�w�A�Y�n���Ҧ��ϥΪ̪��]�w�A�Ы��w
    ECHO '--all-users-known-ext' �ﶵ�C!BIG5_A15E!

    CALL :continue_prompt || GOTO main_exe_ext
)
REM "HideFileExt" is enabled (0x1) if value does not exist.
reg add "HKCU\Software\%ADVANCED_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >NUL || (
    CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
)
IF "!opt_known_ext!"=="ALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        reg add "HKU\%%~i\Software\%ADVANCED_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >NUL || (
            CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
        )
    )
)

:main_exe_ext
IF "!opt_exe_ext!"=="ALWAYS" (
    FOR %%k IN (exefile scrfile) DO (
        reg add "%HKLM_CLS%\%%k" /v "AlwaysShowExt" /t REG_SZ /f >NUL || (
            CALL :show_reg_write_error "HKCR\%%k /v AlwaysShowExt"
        )
    )
    SET opt_exe_ext=FIX
)
IF NOT "!opt_exe_ext!"=="FIX" GOTO main_pif_ext
FOR %%e IN (com exe bat scr cmd) DO (
    CALL :delete_reg_value "%HKLM_CLS%" "%%efile" "NeverShowExt" "HKCR\%%efile /v NeverShowExt"
)
SET list="com=comfile" "exe=exefile" "bat=batfile" "scr=scrfile" "cmd=cmdfile"
CALL :reassoc_file_types !list!

:main_pif_ext
SET "user_msg=�ثe�ϥΪ�"
IF "!opt_reassoc!"=="ALL_USERS" SET "user_msg=�Ҧ��ϥΪ�"

IF "!opt_pif_ext!"=="SKIP" GOTO main_scf_icon
reg query "%HKLM_CLS%\piffile" /v "NeverShowExt" >NUL 2>NUL || GOTO main_scf_icon
REM Thankfully cmd.exe handles .pif right. Only Explorer has this flaw.
ECHO.
ECHO [pif-ext]
ECHO .pif �ɮ׬� DOS �{������!BIG5_AE7C!�CWindows �ɮ��`��!BIG5_B77C!�b�ϥΪ̽ШD�إ� .com �����ɪ���
ECHO !BIG5_AE7C!�ɲ��� .pif �ɡC�M�ӡA�ɮ��`�ަb�B�z���ɮ������ɦ��ӳ]�p�ʳ��A�p�G���H�����
ECHO �ɭ��s�R�W�� .pif ���ɦW�A�ӨϥΪ̶}�Ҹ� .pif �ɮסA�{���X�N!BIG5_B77C!�Q����C���ʳ��i
ECHO �H�Q�Q�ΡC�]�����ɳQ���s�R�W�� .pif �ɮ׫�A!BIG5_B77C!���M�� Windows �����A��ܤ@���ɮ�
ECHO ���ϥܩάO MS-DOS �ϥܡC!BIG5_A15E!
ECHO �ڭ̱N�R�����ɮ������� "NeverShowExt" �n���ȡA�Y�ϥΪ̨����F�u���äw���ɮ�����
ECHO �����ɦW�v�A�L�̱N!BIG5_B77C!�ݨ� .pif �����ɦW�C�o�i����ĵı�C
ECHO �]�o�O�����]�w�C�P��!user_msg!����ɮ����������p!BIG5_B77C!�Q���]�A�Ӧ��L�k�Q�_��C!BIG5_A15E!
CALL :continue_prompt || GOTO main_scf_icon
CALL :delete_reg_value "%HKLM_CLS%" "piffile" "NeverShowExt" "HKCR\piffile /v NeverShowExt"
CALL :reassoc_file_types "pif=piffile"

:main_scf_icon
IF "!opt_scf_icon!"=="SKIP" GOTO main_scrap_ext
reg query "%HKLM_CLS%\SHCmdFile" >NUL 2>NUL || GOTO main_scrap_ext
reg query "%HKLM_CLS%\SHCmdFile" /v "IsShortcut" >NUL 2>NUL && GOTO main_scrap_ext
ECHO.
ECHO [scf-icon]
ECHO .scf �ɮ׬� Windows �ɮ��`�޴߼h�]shell!BIG5_A15E!�����O�ɡC����!BIG5_B77C!�b�ϥΪ̶}�Ҫ��ɭ԰���
ECHO �߼h�������R�O�C�̱`�����Ҥl�� Windows Vista ���e�������ֳt�ҰʦC�W�����u��ܮ�
ECHO ���v�C�]Vista �Τ��᪺�u��ܮୱ�v�ϥܬ� .lnk �ɮסC!BIG5_A15E!�Y�Ϯ榡���������\�{��
ECHO �X�A��߼h���R�O�Q�L�N������ɡA���M���i���~��ϥΪ̡C
ECHO �ڭ̱N�����ɮ������K�[��!BIG5_AE7C!�b�Y�ϥܡA�H�����ϥΪ̪�ĵı�C
ECHO �]�o�O�����]�w�C�P��!user_msg!����ɮ����������p!BIG5_B77C!�Q���]�A�Ӧ��L�k�Q�_��C!BIG5_A15E!
CALL :continue_prompt || GOTO main_scrap_ext
reg add "%HKLM_CLS%\SHCmdFile" /v "IsShortcut" /t REG_SZ /f >NUL || (
    CALL :show_reg_write_error "HKCR\SHCmdFile /v IsShortcut"
)
CALL :reassoc_file_types "scf=SHCmdFile"

:main_scrap_ext
REM Thanks to PCHelp and others for discovering this security flaw. See:
REM http://www.pc-help.org/security/scrap.htm
REM Other references:
REM http://www.trojanhunter.com/papers/scrapfiles/
REM http://www.giac.org/paper/gsec/614/wrapping-malicious-code-windows-shell-scrap-objects/101444
REM WordPad, Office Word and Excel are all known to support scrap files.
IF "!opt_scrap_ext!"=="SKIP" GOTO main_shortcut_icon
SET scrap_ext_keys=
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "%HKLM_CLS%\%%k" /v "NeverShowExt" >NUL 2>NUL && (
        SET scrap_ext_keys=!scrap_ext_keys! %%k
    )
)
IF "!scrap_ext_keys!"=="" GOTO main_shortcut_icon
ECHO.
ECHO [scrap-ext]
ECHO .shs �P .shb �ɮפ��O���x�s���ſ��ơ]scrap!BIG5_A15E!�P���!BIG5_AE7C!���榡�C����!BIG5_B77C!�b�ϥ�
ECHO �̱q���s�边�]�Ҧp WordPad!BIG5_A15E!���즲��r�X�h�ɲ��͡C���榡���\�O�J�i���檺�{��
ECHO �X�A��ϥΪ̶}�Ҥ@�ӡ]�S�O�s�@��!BIG5_A15E!���������ɮסA�{���X�N!BIG5_B77C!�Q����C�]Windows
ECHO Vista �P����w�g�����ſ����ɮת��䴩�C!BIG5_A15E!
ECHO �ڭ̱N�R���o���ɮ������� "NeverShowExt" �n���ȡA�Y�ϥΪ̨����F�u���äw���ɮ���
ECHO �������ɦW�v�A�L�̱N!BIG5_B77C!�ݨ� .shs �P .shb �����ɦW�C�o�i����ĵı�C
ECHO �]�o�O�����]�w�C�P��!user_msg!����ɮ����������p!BIG5_B77C!�Q���]�A�Ӧ��L�k�Q�_��C!BIG5_A15E!
CALL :continue_prompt || GOTO main_shortcut_icon
FOR %%k IN (!scrap_ext_keys!) DO (
    CALL :delete_reg_value "%HKLM_CLS%" "%%k" "NeverShowExt" "HKCR\%%k /v NeverShowExt"
)
CALL :reassoc_file_types "shs=ShellScrap" "shb=DocShortcut"

:main_shortcut_icon
IF NOT "!opt_shortcut_icon!"=="FIX" GOTO main_file_icon
FOR %%k IN (piffile lnkfile DocShortcut InternetShortcut) DO (
    reg query "%HKLM_CLS%\%%k" >NUL 2>NUL && (
        reg add "%HKLM_CLS%\%%k" /v "IsShortcut" /t REG_SZ /f >NUL || (
            CALL :show_reg_write_error "HKCR\%%k /v IsShortcut"
        )
    )
)
reg query "%HKLM_CLS%\Application.Reference" >NUL 2>NUL && (
    reg add "%HKLM_CLS%\Application.Reference" /v "IsShortcut" /t REG_SZ /f >NUL || (
        CALL :show_reg_write_error "Application.Reference /v IsShortcut"
    )
)
REM The data string "NULL" is in the original entry, in both Groove 2007 and
REM SharePoint Workspace 2010.
reg query "%HKLM_CLS%\GrooveLinkFile" >NUL 2>NUL && (
    reg add "%HKLM_CLS%\GrooveLinkFile" /v "IsShortcut" /t REG_SZ /d "NULL" /f >NUL || (
        CALL :show_reg_write_error "HKCR\GrooveLinkFile /v IsShortcut"
    )
)
CALL :delete_reg_value "%HKLM_SFT%" "%SHELL_ICON_SUBKEY%" "29" "Explorer\Shell Icons /v 29"
IF NOT "!opt_file_icon!"=="FIX" (
    SET list="pif=piffile" "lnk=lnkfile" "shb=DocShortcut" "url=InternetShortcut"
    SET list=!list! "appref-ms=Application.Reference" "glk=GrooveLinkFile"
    CALL :reassoc_file_types !list!
)

:main_file_icon
IF NOT "!opt_file_icon!"=="FIX" GOTO main_all_drives
REM "DefaultIcon" for "Unknown" is configurable since Windows Vista.
reg query "%HKLM_CLS%\Unknown\DefaultIcon" >NUL 2>NUL && (
    reg add "%HKLM_CLS%\Unknown\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,0" /f >NUL || (
        CALL :show_reg_write_error "HKCR\Unknown\DefaultIcon"
    )
)
CALL :delete_reg_key "%HKLM_CLS%" "comfile\shellex\IconHandler" "HKCR\comfile\shellex\IconHandler"
reg add "%HKLM_CLS%\comfile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,2" /f >NUL || (
    CALL :delete_reg_key "%HKLM_CLS%" "%%k\DefaultIcon" "HKCR\comfile\DefaultIcon"
)
REM Two vulnerabilities exist in the .lnk and .pif IconHandler:
REM MS10-046 (CVE-2010-2568), MS15-020 (CVE-2015-0096)
REM Windows 2000 has no patch for either. XP has only patch for MS10-046.
REM Expect that user disables the IconHandler as the workaround.
FOR %%k IN (piffile lnkfile) DO (
    reg add "%HKLM_CLS%\%%k\shellex\IconHandler" /ve /t REG_SZ /d "{00021401-0000-0000-C000-000000000046}" /f >NUL || (
        CALL :show_reg_write_error "HKCR\%%k\shellex\IconHandler"
    )
    CALL :delete_reg_key "%HKLM_CLS%" "%%k\DefaultIcon" "HKCR\%%k\DefaultIcon"
)
REM Scrap file types. Guaranteed to work (and only) in Windows 2000 and XP.
FOR %%k IN (ShellScrap DocShortcut) DO (
    reg query "%HKLM_CLS%\%%k" >NUL 2>NUL && (
        reg add "%HKLM_CLS%\%%k\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shscrap.dll,-100" /f >NUL || (
            CALL :show_reg_write_error "HKCR\%%k\DefaultIcon"
        )
        CALL :delete_reg_key "%HKLM_CLS%" "%%k\shellex\IconHandler" "%%k\shellex\IconHandler"
    )
)
REM The "InternetShortcut" key has "DefaultIcon" subkey whose Default value
REM differs among IE versions.
reg query "%HKLM_CLS%\InternetShortcut" >NUL 2>NUL && (
    reg add "%HKLM_CLS%\InternetShortcut\shellex\IconHandler" /ve /t REG_SZ /d "{FBF23B40-E3F0-101B-8488-00AA003E56F8}" /f >NUL || (
        CALL :show_reg_write_error "InternetShortcut IconHandler"
    )
)
reg query "%HKLM_CLS%\SHCmdFile" >NUL 2>NUL && (
    CALL :delete_reg_key "%HKLM_CLS%" "SHCmdFile\DefaultIcon" "HKCR\SHCmdFile\DefaultIcon"
    reg add "%HKLM_CLS%\SHCmdFile\shellex\IconHandler" /ve /t REG_SZ /d "{57651662-CE3E-11D0-8D77-00C04FC99D61}" /f >NUL || (
        CALL :show_reg_write_error "HKCR\SHCmdFile\shellex\IconHandler"
    )
)
reg query "%HKLM_CLS%\Application.Reference" >NUL 2>NUL && (
    CALL :delete_reg_key "%HKLM_CLS%" "Application.Reference\DefaultIcon" "Application.Reference\DefaultIcon"
    reg add "%HKLM_CLS%\Application.Reference\shellex\IconHandler" /ve /t REG_SZ /d "{E37E2028-CE1A-4f42-AF05-6CEABC4E5D75}" /f >NUL || (
        CALL :show_reg_write_error "Application.Reference IconHandler"
    )
)
REM The "GrooveLinkFile" key has "DefaultIcon" value (data: "%1") and no
REM "DefaultIcon" subkey.
reg query "%HKLM_CLS%\GrooveLinkFile" >NUL 2>NUL && (
    reg add "%HKLM_CLS%\GrooveLinkFile\ShellEx\IconHandler" /ve /t REG_SZ /d "{387E725D-DC16-4D76-B310-2C93ED4752A0}" /f >NUL || (
        CALL :show_reg_write_error "GrooveLinkFile\ShellEx\IconHandler"
    )
)
REM We don't reset associations for .url files because user's favorite browser
REM may have its own settings.
SET list="com=comfile" "pif=piffile" "lnk=lnkfile" "shs=ShellScrap"
SET list=!list! "shb=DocShortcut" "scf=SHCmdFile"
SET list=!list! "appref-ms=Application.Reference" "glk=GrooveLinkFile"
CALL :reassoc_file_types !list!

:main_all_drives
ECHO.
ECHO �{�b�ڭ̱N�B�z�Ҧ��Ϻо����ڥؿ��C
ECHO �д��J�Ҧ����c�N�n��v�T���x�s�˸m�A�]�A USB �H���СB�~���w�СB�O�Хd�BPDA�B��
ECHO �z������P�Ʀ�۾��C�p�G�z�� CD- �� DVD-RW ���Цb���о��̡A��ĳ�z�h�X���̡A�H�K
ECHO �~�ҰʿN�����ʧ@�C
IF /I "!opt_move_subdir!"=="NUL" (
    ECHO ���p�i�檺�ܡA�Q�o�{���i�ê��ɮױN!BIG5_B77C!�Q�����R���C
) ELSE (
    ECHO ���p�i�檺�ܡA�Q�o�{���i�ê��ɮױN!BIG5_B77C!�Q���ʨ�Ϻи̦W��
    ECHO "!opt_move_subdir!" ���l�ؿ��C
)
ECHO �p�G�z�b����J 'skip'�A�h���{��!BIG5_B77C!�����C
CALL :continue_prompt || GOTO main_end

REM Symlinks have to be handled first because we can't guarantee that user's
REM 'attrib' utility supports '/L' (don't follow symlinks).
IF NOT "!opt_symlinks!"=="SKIP" (
    ECHO.
    ECHO [symlinks] ^(1 / 7^)
    ECHO �q Windows Vista �}�l�ANTFS �ɮרt�Τ䴩�u�Ÿ��s���v�]symbolic link!BIG5_A15E!�C�Ÿ��s��
    ECHO �O�@�دS���ɮסA�\��������!BIG5_AE7C!�ɡA�]�a����!BIG5_AE7C!���b�Y�ϥܡA���O�Ÿ��s���ݩ��ɮרt
    ECHO �Ϊ��\��A�åB���ݱa�����ɦW�C���Ǵc�N�n��!BIG5_B77C!�إ߫��V�]�c�N!BIG5_A15E!�����ɪ��Ÿ��s���A
    ECHO �H���F�ϥΪ̥h�}�ҥ��̡C
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO �ڭ̱N�R���s��b�ڥؿ����Ҧ����V�ɮס]�D�ؿ�!BIG5_A15E!���Ÿ��s���C
    ) ELSE (
        ECHO �ڭ̱N�����s��b�ڥؿ����Ҧ����V�ɮס]�D�ؿ�!BIG5_A15E!���Ÿ��s���C
        ECHO �`�N�G�ѩ�޳N����A�a���u���áv�Ρu�t�Ρv�ݩʪ��Ÿ��s���Ϧ�!BIG5_B77C!�Q�����R���C
    )
    CALL :continue_prompt || SET opt_symlinks=SKIP
)
REM [attrib] must be done before moving anything, or MOVE refuses to move
REM Hidden or System files.
IF NOT "!opt_attrib!"=="SKIP" (
    ECHO.
    ECHO [attrib] ^(2 / 7^)
    ECHO ���ɮצ��]�w�u���áv�Ρu�t�Ρv�ݩʡA���̴N�w�]��!BIG5_B77C!�b Windows �ɮ��`�ީ� DIR �R
    ECHO �O����ܡC���Ǵc�N�n��!BIG5_B77C!�����ɮסA�ò��ͬۦP�W�٪������ɡ]�άO���V�����ɪ���
    ECHO !BIG5_AE7C!!BIG5_A15E!�A�H���F�ϥΪ̥h�}�ҥ��̡C�]�c�N�n��ä�!BIG5_B77C!�u���R�����ɮסA���M�R���ɮ׮ɪ�
    ECHO �X���ϺЪŶ��ܮe���ް_�ϥΪ̩Ψ��r�n�骺�`�N�C!BIG5_A15E!
    ECHO ���F�w���u�����@�~�t���ɮסA�ڭ̱N�Ѱ��ڥؿ����Ҧ��ɮת��u���áv�P�u�t�Ρv��
    ECHO �ʡC�o�_��Ҧ��Q�c�N�n�鵹���ê��ɮס]�P�ɦ��i����ܴc�N�n���ɮץ���!BIG5_A15E!�C
    CALL :continue_prompt || SET opt_attrib=SKIP
)
IF NOT "!opt_shortcuts!"=="SKIP" (
    ECHO.
    ECHO [shortcuts] ^(3 / 7^)
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO �ڭ̱N�R���ڥؿ����H�U��������!BIG5_AE7C!�ɮסG.pif�B.lnk�B.shb�B.url�B.appref-ms �P
        ECHO .glk.
    ) ELSE (
        ECHO �ڭ̱N�����ڥؿ����H�U��������!BIG5_AE7C!�ɮסG.pif�B.lnk�B.shb�B.url�B.appref-ms �P
        ECHO .glk.
    )
    CALL :continue_prompt || SET opt_shortcuts=SKIP
)
IF NOT "!opt_folder_exe!"=="SKIP" (
    REM COM format does not allow icons and Explorer won't show custom icons
    REM for an NE or PE renamed to .com.
    ECHO.
    ECHO [folder-exe] ^(4 / 7^)
    ECHO ���Ǵc�N�n��!BIG5_B77C!���ø�Ƨ��A�ò��ͬۦP�W�٪������ɡA�q�`�P�ɱa�۸�Ƨ��ϥܡA�H��
    ECHO �F�ϥΪ̥h�}�ҥ��̡C
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO �ڭ̱N�R���s��b�ڥؿ����B�P�{�s��Ƨ��ۦP�W�٪������ɡC!BIG5_B77C!�Q�R�����ɮ�������
        ECHO .exe �P .scr�C
    ) ELSE (
        ECHO �ڭ̱N�����s��b�ڥؿ����B�P�{�s��Ƨ��ۦP�W�٪������ɡC!BIG5_B77C!�Q���ʪ��ɮ�������
        ECHO .exe �P .scr�C
    )
    ECHO ĵ�i�G�o�i��!BIG5_B77C!�v�T��X�k�����ε{���A�Y���ü{�A�и��L���B�J�C
    CALL :continue_prompt || SET opt_folder_exe=SKIP
)
IF NOT "!opt_autorun_inf!"=="SKIP" (
    ECHO.
    ECHO [autorun-inf] ^(5 / 7^)
    ECHO ���Ǵc�N�n��!BIG5_B77C!�إ� autorun.inf �ɮסA�Ϧۤv��b�S������ AutoRun ���q���̳Q�۰�
    ECHO ����C���F���о��H�~�A�䥦�Ϻо��������ӧt���W�� autorun.inf ���ɮסC
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO �ڭ̱N�R�����̡C
    ) ELSE (
        ECHO �ڭ̱N���ʨç⥦�̭��s�R�W�� "!opt_move_subdir!\_autorun.in0"�C
    )
    CALL :continue_prompt || SET opt_autorun_inf=SKIP
)
REM We won't deal with Folder.htt, because technically it could be any name in
REM any location, as specified in Desktop.ini.
IF NOT "!opt_desktop_ini!"=="SKIP" (
    ECHO.
    ECHO [desktop-ini] ^(6 / 7^)
    ECHO �b Windows 98�B2000 �� Me�]�άO�w�ˤF IE4 �� 95 �� NT 4.0!BIG5_A15E!�̡A���ӡu�ۭq�����
    ECHO ���v���\��A�����\�ۭq�ϺЪ��ڸ�Ƨ��B�إߩνs���Ƨ����uWeb �e���v�d���]�q�`
    ECHO �W�� "Folder.htt"!BIG5_A15E!�C�ӽd�����\�O�J JavaScript �� VBScript�A�ӳo�ǫ��O�X!BIG5_A65E!�b��
    ECHO �Ϊ̡u�s���v��Ƨ����ɭԳQ����C
    ECHO �p�G�z�ϥ� Windows 2000 �� XP�A�ڭ̫�ĳ�z�w�˳̷s�� Service Pack�]�ܤ� 2000 SP3
    ECHO �� XP SP1!BIG5_A15E!�H�׸ɤ��\�ۭq�d���ҳy�����w�����I�CVista �P���᪩���O�w�����C
    ECHO "Desktop.ini" �ɮ׫��w�F��Ƨ��n�ϥέ����d���A�M�Ӧb�ڥؿ��̭��A�����Ӧs�b
    ECHO Desktop.ini �ɮסC�]���O�C�� Desktop.ini �\�ೣ�b�ڸ�Ƨ��̦��ġA�Ӧۭq�� Web
    ECHO �e���d���i�Φb�ڸ�Ƨ����ä��O���]�p���@�����C!BIG5_A15E!
    IF /I "!opt_move_subdir!"=="NUL" (
        ECHO �ڭ̱N�R���ڥؿ����� "Desktop.ini" �ɮסC
    ) ELSE (
        ECHO �ڭ̱N�q�ڥؿ������� "Desktop.ini" �ɮסA�ç⥦�̭��s�R�W��
        ECHO "!opt_move_subdir!\_Desktop.in0"�C
    )
    CALL :continue_prompt || SET opt_desktop_ini=SKIP
)
IF "!opt_autorun_inf!.!opt_desktop_ini!"=="SKIP.SKIP" SET opt_mkdir=SKIP
IF NOT "!opt_mkdir!"=="SKIP" (
    ECHO.
    ECHO [mkdir] ^(7 / 7^)
    ECHO ���� autorun.inf �� Desktop.ini �ɮ׫�A���F�קK�c�N�n�魫�s�إߨ䤤���@�ɮסA
    ECHO �ڭ̱N�إ߬ۦP�W�٪����åؿ��A�o�ǥؿ��ϥΪ̬ݤ���A���i�z�Z�c�N�n��A���D�c�N
    ECHO �n�馳��O�R�����̡A�_�h�Ϻо��N��!BIG5_B77C!�A�� AutoRun �P�V�C
    CALL :continue_prompt || SET opt_mkdir=SKIP
)

SET g_files_moved=0
REM The "Windows - No Disk" error dialog is right on USB drives that are not
REM "safely removed", but is a bug to pop up on floppy drives. Guides on the
REM web mostly refer this to malware, or suggest suppressing it. Both are
REM wrong. Instead we just inform the user about the error dialog here.
ECHO.
ECHO �p�G�b�s���Ϻо��N���ɡA�X�{���~��͵��uWindows - �S���Ϥ��CException
ECHO Processing Message c0000013�v�A�Ы��u�����v�C�]�o�b�ųn�о��W�o�ͮɬO���`��!BIG5_A15E!
FOR %%d IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
    IF EXIST %%d:\ (
        CD /D %%d:\
        SET g_move_status=
        ECHO.
        ECHO �Ϻ� %%d�G
        REM Workaround name collisions caused by forced rename.
        SET g_dont_move_files=_autorun.in0 _Desktop.in0 _README.txt
        IF NOT "!opt_symlinks!"=="SKIP" CALL :process_symlinks
        IF NOT "!opt_attrib!"=="SKIP" CALL :clear_files_attrib
        IF NOT "!opt_shortcuts!"=="SKIP" CALL :process_shortcuts
        IF NOT "!opt_folder_exe!"=="SKIP" CALL :process_folder_exes
        IF NOT "!opt_autorun_inf!"=="SKIP" CALL :file_to_directory autorun.inf
        IF NOT "!opt_desktop_ini!"=="SKIP" CALL :file_to_directory Desktop.ini
        REM Process the locked files last.
        SET g_dont_move_files=
        IF NOT "!opt_symlinks!"=="SKIP" CALL :process_symlinks
        IF "!g_move_status!"=="OK_EMPTY" (
            DEL "!opt_move_subdir!\README.txt" >NUL
            RMDIR "!opt_move_subdir!"
        )
    )
)
ECHO.
IF "!g_files_moved!"=="0" (
    ECHO ���������C�����N���������{���C
) ELSE (
    ECHO ���������C���ˬd�U�� "!opt_move_subdir!"
    ECHO �l�ؿ��A�Ҧ��i���ɮ׬ҳQ���ʨ쨺�̤F�C�����N���������{���C
)
PAUSE >NUL
GOTO main_end

:main_help
ECHO.
ECHO   --help                   ��ܦ�����
ECHO   --no-restart             �����s�Ұʸ}���]�w�]!BIG5_B77C!�b������R�O�B�̵{���� AutoRun
ECHO                            �ɭ��s�Ұ�!BIG5_A15E!
ECHO   --no-reg-bak             �����͵n���ƥ��ɮ� "Vacc_reg.bak"
ECHO   --skip-cmd-autorun       ���n�R���R�O�B�̵{���� AutoRun �n����
ECHO   --all-users-cmd-autorun  �R��*�Ҧ��ϥΪ�*�� cmd.exe AutoRun�]�w�]���i��!BIG5_A15E!
ECHO   --no-inf-mapping         ���n���� autorun.inf ����R
ECHO   --skip-mountpoints       ���n�M�z MountPoints �n�����X�]�֨�!BIG5_A15E!
ECHO   --skip-known-ext         ���n��ܤw���ɮ����������ɦW
ECHO   --all-users-known-ext    *�Ҧ��ϥΪ�*����ܤw���ɮ����������ɦW�]�w�]���i��!BIG5_A15E!
ECHO   --fix-exe-ext            �R�������������� NeverShowExt �n���ȡ]�w�]���i��!BIG5_A15E!
ECHO   --always-exe-ext         �û���� .exe �P .scr �ɮ����������ɦW�]�w�]���i��!BIG5_A15E!
ECHO   --skip-pif-ext           ���n�R�� .pif �ɮת� NeverShowExt �n����
ECHO   --skip-scf-icon          ���n�� .scf �ɮײK�[��!BIG5_AE7C!�b�Y�ϥ�
ECHO   --skip-scrap-ext         ���n�R�� .shs �P .shb �ɮת� NeverShowExt �n����
ECHO   --fix-shortcut-icon      �_�챶!BIG5_AE7C!�ɮת��b�Y�ϥܡ]�w�]���i��!BIG5_A15E!
ECHO   --fix-file-icon          �_�쥼�������Bcom�Bpif�Blnk�Bshs�Bshb�Burl�Bscf�B
ECHO                            appref-ms �P glk �ɮ��������ϥܡ]�w�]���i��!BIG5_A15E!
ECHO   --all-users-reassoc      ��s���ɮ����p�ɡA���F�s������w�]�P�ثe�ϥΪ̪��]�w
ECHO                            �~�A�@�֮M�Ψ�*�Ҧ��ϥΪ�*
ECHO �H�U�{�ǬO�M�Φb�Ҧ��Ϻо����ڥؿ��G
ECHO   --move-subdir=�l�ؿ�     �U�ϺЪ��i���ɮ�!BIG5_B77C!�Q���ʨ쪺�l�ؿ�
ECHO                            �]�w�]�G"\MALWARE"!BIG5_A15E!
ECHO   --keep-symlinks          �����ʩΧR���Ÿ��s���]symbolic link!BIG5_A15E!
ECHO   --keep-attrib            �O�d�Ҧ��ɮת��u���áv�P�u�t�Ρv�ݩ�
ECHO   --keep-shortcuts         �����ʩΧR����!BIG5_AE7C!�ɮ�
ECHO   --keep-folder-exe        �����ʩΧR���P��Ƨ��ۦP�W�٪�������
ECHO   --keep-autorun-inf       �����ʩΧR�� autorun.inf
ECHO   --keep-desktop-ini       �����ʩΧR�� Desktop.ini
ECHO   --no-mkdir               ���إߦ��쪺�ؿ�
ECHO ���F�w���ʪ���]�A���}���ä�!BIG5_B77C!�N�i�ê��ɮײ��X�Ϻо��~�C�n�R���ɮצӤ��O���ʪ�
ECHO �ܡA�Ы��w '--move-subdir=NUL'�C
GOTO main_end

:main_end
ENDLOCAL
EXIT /B 0

:main_find_error
ECHO *** �Y�����~�G���O DOS/Windows �� 'find' �R�O�C>&2
ENDLOCAL
EXIT /B 1

:main_invalid_path
ECHO *** �Y�����~�G���w�b '--move-subdir' �ﶵ�̪���!BIG5_AE7C!�L�ġC>&2
ENDLOCAL
EXIT /B 1

:main_restart_native
REM KB942589 hotfix brings Sysnative folder support to Windows XP (IA64 and
REM x64) but is never offered in Windows Update.
%WinDir%\Sysnative\cmd /d /c "%0 --no-restart !args!" && EXIT /B 0
SET status=!ERRORLEVEL!
ECHO *** ������ WoW64 ���������ҡC���}�����ӭn�b�@�~�t�ιw�]�� 64 �줸�R�O��Ķ��>&2
ECHO     �]cmd.exe!BIG5_A15E!�U����C>&2
ECHO �Ы��ӤU�C�B�J�ާ@�G>&2
ECHO 1. ���� "%%WinDir%%\explorer.exe"�]�w�]�B64 �줸�� Windows �ɮ��`�ޡC�`�N���O>&2
ECHO    System32 �� SysWOW64 �ؿ����U�� explorer.exe�C!BIG5_A15E!>&2
ECHO 2. �b�s���ɮ��`�޵����A�s���� "%%WinDir%%\System32"�A�M��M�� "cmd.exe" �æb�W��>&2
ECHO    ���ƹ��k��C>&2
ECHO 3. ����u�H�t�κ޲z����������v�C>&2
ECHO 4. �b�s���R�O���ܦr�������A����U�C�R�O�G>&2
ECHO    %0 !args!>&2
ECHO.
PAUSE
EXIT /B !status!

:main_restart
cmd /d /c "%0 --no-restart !args!" && EXIT /B 0
SET status=!ERRORLEVEL!
ECHO *** ���s�Ұʮɵo�Ϳ��~�C�ХH�U�C�R�O�ӭ��s���榹�}���]�`�N '/d' �P>&2
ECHO     '--no-restart' �ﶵ!BIG5_A15E!�G>&2
ECHO     cmd /d /c ^"%0 --no-restart !args!^">&2
ECHO.
PAUSE
EXIT /B !status!

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Prompts user to continue or skip.
REM @return 0 if user says to continue, or 1 if says to skip
:continue_prompt
    REM Note: If the user answers empty string after a "SET /P", The variable
    REM is kept the previous value and NOT set to the empty string.
    SET prompt=
    SET /P prompt="�Ы� Enter ���~��A�άO��J 'skip' ���L���B�J�G"
    IF "!prompt!"=="" EXIT /B 0
    IF /I "!prompt!"=="Y" EXIT /B 0
    IF /I "!prompt!"=="SKIP" EXIT /B 1
    GOTO continue_prompt
GOTO :EOF

REM Checks if file exists and creates one if not.
REM @param %1 File name
REM @return 0 if file is created
:create_file
    REM Non-atomic! A race or a TOCTTOU attack may occur.
    IF EXIST %1 EXIT /B 1
    TYPE NUL >>%1
    IF EXIST %1 EXIT /B 0
    EXIT /B 1
GOTO :EOF

REM Creates and initializes "Vacc_reg.bak"
:init_reg_bak
    REM This is not .reg format! So we don't allow user to specify file name.
    CALL :create_file "Vacc_reg.bak" || (
        SET g_reg_bak=FAIL
        ECHO.>&2
        ECHO ĵ�i�G�L�k�b���ؿ��̫إߵn���ƥ��� "Vacc_reg.bak">&2
        ECHO "!CD!"!BIG5_A15E!>&2
        ECHO �i��w�g�s�b�ۦP�W�٪��ɮסA�άO���ؿ��O��Ū���C>&2
        ECHO ���{���N!BIG5_B77C!�b�S���n���ƥ������p�U�~��C>&2
        PAUSE
        GOTO :EOF
    )
    SET g_reg_bak=OK
    (
        REM Don't localize.
        ECHO ; Registry backup generated by 'usb_vaccine.cmd'. Project website:
        ECHO ; ^<https://github.com/Explorer09/usb_vaccine^>
    ) >>"Vacc_reg.bak"
    ECHO.
    ECHO �z���n���N!BIG5_B77C!�ƥ��b���ɮ׸̡G
    FOR %%i IN (Vacc_reg.bak) DO (
        ECHO "%%~fi"
    )
    PAUSE
GOTO :EOF

REM Logs data of a registry key/value into "Vacc_reg.bak".
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 (Without quotes:) "/v", "/ve" (default value) or "" (whole key)
REM @param %4 Value name if "%3"=="/v", empty otherwise
REM @return 0 on success, 1 if key/value doesn't exist, 2 if backup file fails
:backup_reg
    REM With '/ve' option, 'reg' in Windows 2000/XP exits with 1 on a "value
    REM not set" default, while in Vista it exits with 0. We ensures Vista's
    REM behavior by querying the whole key.
    SET "v_opt=%3"
    reg query "%~1\%~2" !v_opt:/ve=! %4 >NUL 2>NUL || EXIT /B 1
    IF "!g_reg_bak!"=="" CALL :init_reg_bak
    IF "!g_reg_bak!"=="FAIL" EXIT /B 2
    IF "!g_is_wow64!%~1"=="1%HKLM_SFT%" (
        REM Don't localize.
        ECHO ; WoW64 redirected key. Actual key name is
        ECHO ; "%HKLM_SFT_WOW%\%~2"
    ) >>"Vacc_reg.bak"
    SET s=
    IF "%~3%~4"=="" SET s=/s
    reg query "%~1\%~2" %3 %4 !s! >>"Vacc_reg.bak" 2>NUL
GOTO :EOF

REM Displays a (generic) error message for any write error in registry.
REM @param %1 Short text about the key or value.
:show_reg_write_error
    ECHO �ק�n���ɵo�Ϳ��~�G"%~1">&2
    IF "!g_has_error_shown!"=="1" GOTO :EOF
    SET g_has_error_shown=1
    ECHO �z�i��ݭn�Ψt�κ޲z�����v�����s���榹�{���C>&2
    PAUSE
GOTO :EOF

REM Deletes a non-default registry value (if it exists).
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 Value name
REM @param %4 Short text about the entry, displayed in error messages
REM @return 0 on successful deletion, 1 if key doesn't exist, or 2 on error
:delete_reg_value
    CALL :backup_reg %1 %2 /v %3
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg delete "%~1\%~2" /v "%~3" /f >NUL && EXIT /B 0
    CALL :show_reg_write_error %4
    EXIT /B 2
GOTO :EOF

REM Prepares g_sids global variable (list of all user SIDs on the computer).
:prepare_sids
    IF NOT "!g_sids!"=="" GOTO :EOF
    FOR /F "usebackq eol=\ delims=" %%k IN (`reg query HKU 2^>NUL`) DO (
        REM 'reg' outputs junk lines, make sure the line truly represents a
        REM user and not a Classes key.
        SET "key=%%~k"
        IF /I "!key:~0,11!"=="HKEY_USERS\" (
            IF /I NOT "!key:~-8!"=="_Classes" (
                SET g_sids=!g_sids! "!key:~11!"
            )
        )
    )
GOTO :EOF

REM Deletes a registry key (if it exists).
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 Short text about the key, displayed in error messages
REM @return 0 on successful deletion, 1 if key doesn't exist, or 2 on error
:delete_reg_key
    CALL :backup_reg %1 %2
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg delete "%~1\%~2" /f >NUL && EXIT /B 0
    CALL :show_reg_write_error %3
    EXIT /B 2
GOTO :EOF

REM Cleans a registry key (if it exists).
REM @param %1 Part of key name up to and including the "Wow6432Node" delimiter
REM @param %2 Sub-key name after "%1\"
REM @param %3 Short text about the key, displayed in error messages
REM @return 0 on successful deletion, 1 if key doesn't exist, or 2 on error
:clean_reg_key
    CALL :delete_reg_key %1 %2 %3 || GOTO :EOF
    REM Create a dummy value so that "reg add" won't affect the default value
    REM of the key.
    reg add "%~1\%~2" /v "X" /f >NUL 2>NUL || EXIT /B 2
    reg delete "%~1\%~2" /v "X" /f >NUL 2>NUL || EXIT /B 2
GOTO :EOF

REM Changes file association for a file type.
REM @param %1 File extension
REM @param %2 ProgID
REM @return 0 on success, 1 if not both .%1 and %2 keys exist, or 2 on error
:safe_assoc
    reg query "%HKLM_CLS%\%~2" >NUL 2>NUL || EXIT /B 1
    CALL :backup_reg "%HKLM_CLS%" ".%~1" /ve
    IF "!ERRORLEVEL!"=="1" EXIT /B 1
    reg add "%HKLM_CLS%\.%~1" /ve /t REG_SZ /d "%~2" /f >NUL && EXIT /B 0
    CALL :show_reg_write_error "%HKLM_CLS%\.%~1"
    EXIT /B 2
GOTO :EOF

REM Resets file associations for given file types.
REM @param %* List of extensions in "ext=ProgID" (quoted) data pairs.
:reassoc_file_types
    REM p[air], e[xt], i[d], k[ey]
    SET keys=
    FOR %%p IN (%*) DO (
        FOR /F "tokens=1,2 delims==" %%e IN (%%p) DO (
            CALL :safe_assoc "%%e" "%%f" && SET keys=!keys! ".%%e" "%%f"
        )
    )
    FOR %%k IN (!keys!) DO (
        CALL :delete_reg_key "HKCU\Software\Classes" "%%~k" "HKCU Classes\%%~k"
    )
    IF NOT "!opt_reassoc!"=="ALL_USERS" GOTO :EOF
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%~i
        FOR %%k IN (!keys!) DO (
            CALL :delete_reg_key "HKU\%%~i\Software\Classes" "%%~k" "HKU Classes\%%~k"
        )
    )
GOTO :EOF

REM Checks if the name matches (regex) "WINLFN[1-9a-f][0-9a-f]*.INI"
REM @param %1 File name
REM @return 0 (true) if it matches
:is_winlfn_name
    SET "name=%~1"
    IF /I NOT "!name:~0,6!!name:~-4!"=="WINLFN.INI" EXIT /B 1
    IF "!name:~6,1!"=="0" EXIT /B 1
    SET "name=!name:~6,-4!"
    IF "!name!"=="" EXIT /B 0
    FOR %%c IN (0 1 2 3 4 5 6 7 8 9 A B C D E F a b c d e f) DO (
        SET "name=!name:%%c=!"
        IF "!name!"=="" EXIT /B 0
    )
    EXIT /B 1
GOTO :EOF

REM Checks if the file is in one of the list of files to keep.
REM @param %1 Category
REM @param %2 Name of file to check
REM @return 0 (true) if the file is in the list
:is_file_to_keep
    SET list=
    IF "%~1"=="SYMLINK"   SET list=!KEEP_SYMLINK_FILES!
    IF "%~1"=="HS_ATTRIB" SET list=!KEEP_HS_ATTRIB_FILES!
    IF "%~1"=="H_ATTRIB"  SET list=!KEEP_H_ATTRIB_FILES!
    IF "%~1"=="S_ATTRIB"  SET list=!KEEP_S_ATTRIB_FILES!
    IF "%~1"=="EXECUTE"   SET list=!KEEP_EXECUTE_FILES!
    REM Special case for OS/2 "EA DATA. SF" and "WP ROOT. SF", which MUST
    REM contain spaces in their short name form.
    FOR %%i IN ("EA DATA. SF" "WP ROOT. SF") DO (
        IF /I "%~2"==%%i (
            IF /I NOT "%~s2"==%%i EXIT /B 1
        )
    )
    SET attr_d=0
    ECHO.%~a2 | find "d" >NUL && SET attr_d=1
    FOR %%i IN (!list!) DO (
        IF /I "!attr_d!%~2"=="0%%~i" EXIT /B 0
        IF /I "!attr_d!%~2\"=="1%%~i" EXIT /B 0
    )
    REM Special case for "WINLFN<hex>.INI"
    IF "%~1!attr_d!"=="HS_ATTRIB0" (
        CALL :is_winlfn_name %2 && EXIT /B 0
    )
    EXIT /B 1
GOTO :EOF

REM Creates and initializes directory specified by opt_move_subdir.
:init_move_subdir
    IF /I "!opt_move_subdir!"=="NUL" (
        SET g_move_status=DEL
        GOTO :EOF
    )
    MKDIR "!opt_move_subdir!" || (
        REM We default not to touch the files if move_subdir can't be created.
        REM Change this value to DEL if you want to delete files instead.
        SET g_move_status=DONT
        ECHO ���~�G�L�k�b�Ϻо� !CD:~0,2! �W�إߥؿ� "!opt_move_subdir!"�C>&2
        ECHO �ϺФ��i��w�g�s�b�ۦP�W�٪��ɮסA�άO�Ϻо��O��Ū���C>&2
        GOTO :EOF
    )
    SET g_move_status=OK_EMPTY
    (
        ECHO ^(zh-TW.Big5^)
        ECHO.
        ECHO �Ҧ��Q�}�� 'usb_vaccine.cmd' �P�w���i�ê��ɮ׬ҳQ���ʨ즹�ؿ��̤F�A���O�ѩ�
        ECHO 'usb_vaccine.cmd' �ä��O���r�n��A���i��!BIG5_B77C!�����~���P�_�C���ˬd���ؿ��̪��C����
        ECHO �סA�T�{�䤤�z�S���Q�n�O�d����ơC
        ECHO.
        ECHO �p�G�z�n�O�d�ɮסA�����N����!BIG5_A65E!�ϺЪ��ڥؿ��Y�i�C�o�̪��ɮ׭쥻���s��b�ڥؿ��C
        ECHO.
        ECHO ��z�����F����A�ЧR�����ؿ��C
        ECHO.
        ECHO 'usb_vaccine.cmd' �M�׺����G
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"!opt_move_subdir!\README.txt"
GOTO :EOF

REM Important notes about commands behaviors:
REM - MOVE command exits with 1 when a move error occurs. There's no way to
REM   specify "don't overwrite" option for MOVE command.
REM - DEL command exits with 1 only when arguments syntax or path is invalid.
REM   It's exit code does not distinguish between deletion success and failure.
REM - Both MOVE and DEL refuse to process files with Hidden or System (or both)
REM   attribute set. (They'll output the "could not find" error.) However since
REM   Windows NT, DEL supports '/A' option that can workaround this.
REM - 'attrib' utility without '/L' option follows symlinks when reading or
REM   changing attributes. '/L' is not available before Windows Vista.
REM - The %~a1 method will retrieve attributes of the link itself, if the file
REM   referenced by %1 is a link (junction or symlink).
REM - If "dirlink" is a directory link (attributes "DL"), "DEL dirlink" deletes
REM   all files in the target directory (DANGEROUS), while "RMDIR dirlink"
REM   (with or without '/S') removes the symlink without touching anything in
REM   the target directory (SAFE). MOVE command on links always processes links
REM   themselves rather than link targets.

REM Decides the file and keeps, moves, or deletes it according to decision.
REM @param %1 Category of list of files to keep
REM @param %2 Type of file, displayed in (localized) messages
REM @param %3 Name of file to process
:process_file
    SET "type=%~2"
    IF "%~2"=="��AE7C�ɮ�" SET "type=��!BIG5_AE7C!�ɮ�"
    CALL :is_file_to_keep %1 %3 && (
        ECHO ���F�w����]�A���L!type! "%~3"
        GOTO :EOF
    )
    FOR %%A IN (h s d l) DO (
        SET "attr_%%A=-%%A"
        ECHO.%~a3 | find "%%A" >NUL && SET "attr_%%A=%%A"
    )
    REM Always Delete Hidden or System symlinks.
    IF NOT "!attr_h!!attr_s!"=="-h-s" (
        IF "!attr_l!!attr_d!"=="l-d" (
            ECHO �R���Ÿ��s�� "%~3"
            DEL /F /A:!attr_h!!attr_s!l-d "%~3" >NUL
            GOTO :EOF
        )
    )
    IF "!g_move_status!"=="" CALL :init_move_subdir
    IF "!g_move_status!"=="DEL" (
        IF "!attr_d!"=="d" GOTO :EOF
        ECHO �R��!type! "%~3"
        DEL /F /A:!attr_h!!attr_s!!attr_l!-d "%~3" >NUL
        GOTO :EOF
    )
    IF NOT "!g_move_status:~0,2!"=="OK" (
        ECHO ���������!BIG5_B77C!����!type! "%~3"
        GOTO :EOF
    )
    FOR %%i IN (!g_dont_move_files!) DO (
        IF /I "%~3"=="%%~i" GOTO :EOF
    )
    IF NOT "!attr_h!!attr_s!"=="-h-s" (
        ECHO �L�k����!type! "%~3"�C�]�����éΨt���ݩ�!BIG5_A15E!>&2
        GOTO :EOF
    )
    SET "dest=%~3"
    IF /I "%~3"=="autorun.inf" SET dest=_autorun.in0
    IF /I "%~3"=="Desktop.ini" SET dest=_Desktop.in0
    IF /I "%~3"=="README.txt" SET dest=_%~3
    REM Should never exist name collisions except the forced rename above.
    IF EXIST "!opt_move_subdir!\!dest!" (
        ECHO �L�k����!type! "%~3" �� "!opt_move_subdir!"�C�]�ت��a�ɮפw�s�b!BIG5_A15E!>&2
        GOTO :EOF
    )
    MOVE /Y "%~3" "!opt_move_subdir!\!dest!" >NUL || (
        ECHO �L�k����!type! "%~3" �� "!opt_move_subdir!"�C>&2
        GOTO :EOF
    )
    SET g_move_status=OK_MOVED
    SET g_files_moved=1
    ECHO �w����!type! "%~3" �� "!opt_move_subdir!"�C
GOTO :EOF

REM Moves or deletes all file symlinks in current directory.
:process_symlinks
    REM Directory symlinks/junctions are harmless. Leave them alone.
    REM DIR command in Windows 2000 supports "/A:L", but displays symlinks
    REM (file or directory) as junctions. Undocumented feature.
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:L-D /B 2^>NUL`) DO (
        CALL :process_file SYMLINK "�Ÿ��s��" "%%~f"
    )
GOTO :EOF

REM Clears hidden and system attributes of all files in current directory.
:clear_files_attrib
    REM 'attrib' refuses to clear either H or S attribute for files with both
    REM attributes set. Must clear both simultaneously.
    REM The exit code of 'attrib' is unreliable.
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:HS-L /B 2^>NUL`) DO (
        CALL :is_file_to_keep HS_ATTRIB "%%~f"
        IF ERRORLEVEL 1 (
            ECHO �Ѱ�����+�t���ݩ� "%%~f"
            attrib -H -S "%%~f"
        ) ELSE (
            ECHO ���F�w����]�A���L�ɮ� "%%~f"�]����+�t���ݩ�!BIG5_A15E!
        )
    )
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:H-S-L /B 2^>NUL`) DO (
        CALL :is_file_to_keep H_ATTRIB "%%~f"
        IF ERRORLEVEL 1 (
            ECHO �Ѱ������ݩ� "%%~f"
            attrib -H "%%~f"
        ) ELSE (
            ECHO ���F�w����]�A���L�ɮ� "%%~f"�]�����ݩ�!BIG5_A15E!
        )
    )
    FOR /F "usebackq eol=\ delims=" %%f IN (`DIR /A:S-H-L /B 2^>NUL`) DO (
        CALL :is_file_to_keep S_ATTRIB "%%~f"
        IF ERRORLEVEL 1 (
            ECHO �Ѱ��t���ݩ� "%%~f"
            attrib -S "%%~f"
        ) ELSE (
            ECHO ���F�w����]�A���L�ɮ� "%%~f"�]�t���ݩ�!BIG5_A15E!
        )
    )
GOTO :EOF

REM Moves or deletes shortcut files in current directory.
:process_shortcuts
    FOR /F "usebackq eol=\ delims=" %%f IN (
        `DIR /A:-D /B *.pif *.lnk *.shb *.url *.appref-ms *.glk 2^>NUL`
    ) DO (
        CALL :process_file EXECUTE "��AE7C�ɮ�" "%%~f"
    )
GOTO :EOF

REM Moves or deletes all .exe and .scr files that carry the same name as a
REM folder in current directory.
:process_folder_exes
    REM .bat, .cmd and .com are self-executable, but their icons are static, so
    REM leave them alone.
    FOR /F "usebackq eol=\ delims=" %%d IN (`DIR /A:D /B 2^>NUL`) DO (
        FOR /F "usebackq eol=\ delims=" %%f IN (
            `DIR /A:-D /B "%%~d.exe" "%%~d.scr" 2^>NUL`
        ) DO (
            CALL :process_file EXECUTE "�ɮ�" "%%~f"
        )
    )
GOTO :EOF

REM Removes a file and optionally creates a directory with the same name.
REM @param %1 Name of file to remove or directory to create
REM @return 0 if directory exists or is created successfully, or 1 on error
:file_to_directory
    IF EXIST %1 (
        ECHO.%~a1 | find "d" >NUL && (
            REM File exists and is a directory. Keep it.
            attrib +R +H +S "%~1"
            EXIT /B 0
        )
        CALL :process_file 0 "�ɮ�" %1
        IF EXIST %1 EXIT /B 1
    )
    IF "!opt_mkdir!"=="SKIP" EXIT /B 0
    MKDIR "%~1" || (
        ECHO �إߥؿ� "%~1" �ɵo�Ϳ��~>&2
        EXIT /B 1
    )
    (
        REM Should be in ASCII encoding. It is better to keep an English
        REM version as well as localized one.
        ECHO This directory, "%~1", is to protect your disk from injecting a
        ECHO malicious %1 file.
        ECHO Your disk may still carry the USB or AutoRun malware, but it will NOT be
        ECHO executed anymore.
        ECHO Please do not remove this directory. If you do, you'll lose the protection.
        ECHO.
        ECHO This directory is generated by 'usb_vaccine.cmd'. Project website:
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"%~1\DONT_DEL.txt"
    ECHO.>"%~1\dummy"
    attrib +R +H +S "%~1\dummy"
    attrib +R +H +S "%~1"
    EXIT /B 0
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
