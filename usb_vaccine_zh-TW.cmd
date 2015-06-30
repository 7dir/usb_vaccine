@ECHO OFF
SETLOCAL EnableExtensions
IF CMDEXTVERSION 2 GOTO cmd_ext_ok
ENDLOCAL
echo Requires Windows 2000 or later.
GOTO EOF
exit
:cmd_ext_ok
ENDLOCAL
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
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

REM User's default options for DIR command. Reset.
SET DIRCMD=

SET CMD_REG_SUBKEY=Software\Microsoft\Command Processor
SET INF_MAPPING_REG_KEY="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET MOUNT2_REG_SUBKEY=Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2
SET ADVANCED_REG_SUBKEY=Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
SET SHELL_ICON_REG_KEY="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons"

REM BIG5 �\�\�\���D workaround
SET "BIG5_A15E=�^"
SET "BIG5_AE7C=�|"
SET "BIG5_B77C=�|"

REM Files to keep - these are REAL system files and it's best to leave these
REM untouched. (Last updated for Windows 10 Insider Preview build 10074)

SET KEEP_SYMLINK_FILES=
FOR %%i IN (
) DO (
    SET KEEP_SYMLINK_FILES=!KEEP_SYMLINK_FILES! %%i
)
SET KEEP_HS_ATTRIB_FILES=
FOR %%i IN (
    "System Volume Information\"

    "autoexec.bat"
    "config.sys"
    "IO.SYS"
    "MSDOS.SYS"

    "BOOT.BAK"
    "boot.ini"
    "bootfont.bin"
    "NTDETECT.COM"
    "ntldr"

    "RECYCLER\"
    "$Recycle.Bin\"

    "Boot\"
    "bootmgr"
    "BOOTSECT.BAK"
    "BOOTNXT"

    "hiberfil.sys"
    "pagefile.sys"
    "swapfile.sys"

    "cmdcons\"
    "cmldr"

    "Recovery\"
) DO (
    SET KEEP_HS_ATTRIB_FILES=!KEEP_HS_ATTRIB_FILES! %%i
)
SET KEEP_H_ATTRIB_FILES=
FOR %%i IN (
    "ProgramData\"
    "MSOCache\"
) DO (
    SET KEEP_H_ATTRIB_FILES=!KEEP_H_ATTRIB_FILES! %%i
)
SET KEEP_S_ATTRIB_FILES=
FOR %%i IN (
) DO (
    SET KEEP_S_ATTRIB_FILES=!KEEP_S_ATTRIB_FILES! %%i
)
SET KEEP_EXECUTE_FILES=
FOR %%i IN (
    "autoexec.bat"
    "NTDETECT.COM"
) DO (
    SET KEEP_EXECUTE_FILES=!KEEP_EXECUTE_FILES! %%i
)

REM ---------------------------------------------------------------------------
REM MAIN

SET g_sids=

REM Needed by restart routine. SHIFT will change %*.
SET "args=%*"

:main_parse_options
IF NOT "X%~1"=="X" (
    SET "arg1=%~1"
    IF "X!arg1!"=="X/?" (
        SET opt_help=1
        SET opt_restart=SKIP
    )
    IF "X!arg1!"=="X-?" (
        SET opt_help=1
        SET opt_restart=SKIP
    )
    IF "X!arg1!"=="X--help" (
        SET opt_help=1
        SET opt_restart=SKIP
    )
    IF "X!arg1!"=="X--default-shortcut-icon" (
        SET "opt_shortcut_icon=DEFAULT"
    )
    IF "X!arg1:~0,5!"=="X--no-" (
        FOR %%i IN (restart inf_mapping mkdir) DO (
            IF "!arg1:-=_!"=="__no_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,7!"=="X--skip-" (
        FOR %%i IN (cmd_autorun mountpoints2 known_ext shortcut_icon) DO (
            IF "!arg1:-=_!"=="__skip_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,7!"=="X--keep-" (
        FOR %%i IN (symlinks attrib shortcuts folder_exe files) DO (
            IF "!arg1:-=_!"=="__keep_%%i" (
                SET "opt_%%i=SKIP"
            )
        )
    )
    IF "X!arg1:~0,12!"=="X--all-users-" (
        FOR %%i IN (cmd_autorun known_ext) DO (
            IF "!arg1:-=_!"=="__all_users_%%i" (
                SET "opt_%%i=ALL_USERS"
            )
        )
    )
    REM %0 is needed by restart routine. Don't touch.
    SHIFT /1
    GOTO main_parse_options
)

:main_sanity_test
REM Humbly quit when we get a Unix 'find' utility. We won't bother with 'grep'.
find . -prune >nul 2>nul && (
    ECHO *** �Y�����~�G���O DOS/Windows �� 'find' �R�O�C>&2
    ENDLOCAL
    EXIT /B 1
)
reg query "HKCU" >nul 2>nul || (
    ECHO.
    ECHO *** ���~�G�L�k�ϥ� reg.exe �Ӧs�� Windows �n���I>&2
    ECHO.
    ECHO �p�G�z�ϥ� Windows 2000�A�Цw�� Windows 2000 �䴩�u��C
    ECHO �Ա��Ш� ^<https://support.microsoft.com/kb/301423^>�A�z�i�H�q���U���䴩�u��G
    ECHO ^<https://www.microsoft.com/download/details.aspx?id=18614^>
    IF "X!opt_help!"=="X1" GOTO main_help
    ECHO.
    ECHO �Ҧ��n���ɤu�@�N!BIG5_B77C!�Q���L�C
    GOTO main_all_drives
)

:main_cmd_autorun
SET has_cmd_autorun=0
FOR %%k IN (HKLM HKCU) DO (
    REM "reg query" always output blank lines. Suppress them.
    reg query "%%k\%CMD_REG_SUBKEY%" /v "AutoRun" >nul 2>nul && (
        SET has_cmd_autorun=1
        IF NOT "X!opt_restart!"=="XSKIP" GOTO main_restart
        REM Show user the AutoRun values along with error message below.
        REM Key name included in "reg query" output.
        reg query "%%k\%CMD_REG_SUBKEY%" /v "AutoRun" >&2
    )
)
IF "!has_cmd_autorun!"=="1" (
    ECHO *** ĵ�i�G�b���T����ܤ��e�A�z���R�O��Ķ�� ^(cmd.exe^) �w�g�۰ʰ���F�@�ǩR�O�A�o>&2
    ECHO     �ǩR�O�i�ର�c�N�{���C>&2
)
IF "X!opt_help!"=="X1" GOTO main_help
IF "X!opt_cmd_autorun!"=="XSKIP" GOTO main_inf_mapping
IF "!has_cmd_autorun!"=="1" (
    IF NOT "X!opt_cmd_autorun!"=="XALL_USERS" (
        ECHO.
        ECHO [cmd-autorun]
        ECHO ���F�w���ʪ���]�A�b "{HKLM,HKCU}\%CMD_REG_SUBKEY%" ��Ӿ�
        ECHO �X�̭��� "AutoRun" �n���ȱN!BIG5_B77C!�Q�R���C
        ECHO �]�v�T�����P�ثe�ϥΪ̪��]�w�A�Y�n�P�ɧR���䥦�ϥΪ̪��]�w�A�Ы��w
        ECHO '--all-users-cmd-autorun' �ﶵ�C���ʧ@�L�k�_��C!BIG5_A15E!
        CALL :continue_prompt || GOTO main_inf_mapping
    )
    FOR %%k IN (HKLM HKCU) DO (
        CALL :delete_reg_value "%%k\%CMD_REG_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)
IF "X!opt_cmd_autorun!"=="XALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%i
        CALL :delete_reg_value "HKU\%%i\%CMD_REG_SUBKEY%" "AutoRun" "Command Processor /v AutoRun"
    )
)

:main_inf_mapping
SET has_reg_inf_mapping=1
reg query %INF_MAPPING_REG_KEY% /ve 2>nul | find /I "@SYS:" >nul || (
    SET has_reg_inf_mapping=0
    ECHO.
    ECHO *** ĵ�i�G�z���q������ AutoRun �c�N�n�骺�����I>&2
)
ECHO.
ECHO ���{���i�H���U�z�����۰ʰ��� ^(AutoRun^)�B�M�z�z�Ϻи̪� autorun.inf �ɮסB�R����
ECHO !BIG5_AE7C!����ܳQ���ê��ɮסC�o�ǰʧ@�_�� AutoRun �c�N�n�鰵�y�����ˮ`�C
ECHO ���{���u�ä�!BIG5_B77C!�v�����c�N�n�饻���A�ҥH����ΨӨ��N���r�n��C�Цw�ˤ@�M���r�n��
ECHO �ӫO�@�z���q���C
ECHO �p�G�z�ϥ� Windows 2000, XP, Server 2003, Vista �� Server 2008�A�ڭ̱j�P��ĳ�z
ECHO �w�˷L�n�� KB967715 �P KB971029 ��s�A���G��s�ץ��F AutoRun ��@�����Ρ]�Y�ϧ�
ECHO ��!BIG5_B77C!����Ҧ��� AutoRun!BIG5_A15E!�C
ECHO �Ш� ^<https://technet.microsoft.com/library/security/967940.aspx^>

REM Credit to Nick Brown for the solution to disable AutoRun. See:
REM http://archive.today/CpwOH
REM http://www.computerworld.com/article/2481506
REM Works with Windows 7 too, and I believe it's safer to disable ALL AutoRuns
REM in Windows 7, rather than let go some devices.
REM Other references:
REM http://www.kb.cert.org/vuls/id/889747
REM https://www.us-cert.gov/ncas/alerts/TA09-020A
IF "!has_reg_inf_mapping!"=="1" GOTO main_mountpoints2
IF "X!opt_inf_mapping!"=="XSKIP" GOTO main_mountpoints2
ECHO.
ECHO [inf-mapping]
ECHO Windows �b�w�]���p�U!BIG5_B77C!�b�z��J���СA�ηƹ��I�����о��ϥܮɡA�۰ʰ���Y�ǡ]�w
ECHO ��!BIG5_A15E!�{���C�쥻�O���Ѥ�K�A�����]�p�o�e���Q�c�N�n��Q�ΡA�b�ϥΪ̥��dı�����p�U
ECHO �۰ʰ���C
ECHO �ڭ̱N�����Ҧ��۰ʰ��� ^(AutoRun^)�A�ð��� Windows ��R���� autorun.inf �ɮסA�]
ECHO �A���о��C���� AutoRun ��A�p�G�z�n�q���и̭��w�˩ΰ���n��A�z��������I���̭�
ECHO �� Setup.exe�C�o���v�T���֡A�q�v���СA�� USB �˸m���۰ʼ��� ^(AutoPlay^) �\��C
ECHO �]�o�O�����]�w�C!BIG5_A15E!
CALL :continue_prompt || GOTO main_mountpoints2
reg add %INF_MAPPING_REG_KEY% /ve /t REG_SZ /d "@SYS:DoesNotExist" /f >nul || (
    CALL :show_reg_write_error "IniFileMapping\autorun.inf"
    GOTO main_mountpoints2
)
CALL :delete_reg_key "HKLM\SOFTWARE\DoesNotExist" "HKLM\SOFTWARE\DoesNotExist"

:main_mountpoints2
IF "X!opt_mountpoints2!"=="XSKIP" GOTO main_known_ext
ECHO.
ECHO [mountpoints2]
ECHO MountPoints2 �n�����X���@�~�t�� AutoRun ���֨���ơA�b AutoRun ��������A�M�z��
ECHO �X�H�קK���e�˸m�� AutoRun �¯١C
ECHO �]�v�T�Ҧ��ϥΪ̪��]�w�C���ʧ@�L�k�_��C!BIG5_A15E!
CALL :continue_prompt || GOTO main_known_ext
CALL :prepare_sids
FOR %%i IN (!g_sids!) DO (
    ECHO SID %%i
    CALL :clean_reg_key "HKU\%%i\%MOUNT2_REG_SUBKEY%" "Explorer\MountPoints2"
)

:main_known_ext
REM The value shouldn't exist in HKLM and doesn't work there. Silently delete.
reg delete "HKLM\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /f >nul 2>nul

IF "X!opt_known_ext!"=="XSKIP" GOTO main_shortcut_icon
REM We include PIF because it's executable in Windows!
REM It's possible to rename a PE .exe to .pif and run when user clicks it.
IF NOT "X!opt_known_ext!"=="XALL_USERS" (
    ECHO.
    ECHO [known-ext]
    ECHO Windows �w�]�N�w���ɮ����������ɦW���ð_�ӡC���O�A�ѩ����ε{�����ۭq���ϥܡA�b
    ECHO ���ɦW���ê��ɭԡA�c�N�{���i�H�ϥιϥܨӰ��˦��@���ɮסA���F�ϥΪ̥h�I�����̡C
    ECHO �ڭ̱N�����u����x�v���u��Ƨ��ﶵ�v���u���äw���ɮ����������ɦW�v�A�ϱo�`�Ϊ�
    ECHO ���ɦW�]����!BIG5_AE7C!�~!BIG5_A15E!�û��Q��ܡC�ϥΪ̥i�H�z�L���ɦW�ӿ�{�ɮ׬O�_���]�c�N!BIG5_A15E!����
    ECHO �ɡA�H�U���ɦW���i�����ɡG
    ECHO     .exe�]���ε{��!BIG5_A15E!           .bat�]�妸�ɮ�!BIG5_A15E!
    ECHO     .com�]MS-DOS ���ε{��!BIG5_A15E!    .cmd�]Windows NT �R�O�}��!BIG5_A15E!
    ECHO     .scr�]�ù��O�@�{��!BIG5_A15E!       .pif�]MS-DOS �{����!BIG5_AE7C!!BIG5_A15E!
    ECHO �ڭ�!BIG5_B77C!�P�ɧR���H�W�ɮ������� "NeverShowExt" �n���ȡA�ӵn����!BIG5_B77C!�û����ø��ɮ���
    ECHO �������ɦW�A���F��!BIG5_AE7C!�ɥH�~�����s�b�ӵn���ȡC
    ECHO �]�v�T�����P�ثe�ϥΪ̪��]�w�A�Y�n�P�ɧ��䥦�ϥΪ̪��]�w�A�Ы��w
    ECHO '--all-users-known-ext' �ﶵ�C!BIG5_A15E!
    CALL :continue_prompt || GOTO main_shortcut_icon
)
REM "HideFileExt" is enabled (0x1) if value does not exist.
reg add "HKCU\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul || (
    CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
)
REM "NeverShowExt"
FOR %%e IN (exe com scr bat cmd pif) DO (
    CALL :delete_reg_key "HKCU\Software\Classes\.%%e" "HKCU\Software\Classes\.%%e"
    CALL :delete_reg_key "HKCU\Software\Classes\%%efile" "HKCU\Software\Classes\%%efile"
    reg add "HKLM\SOFTWARE\Classes\.%%e" /ve /t REG_SZ /d "%%efile" /f >nul || (
        CALL :show_reg_write_error "HKLM\SOFTWARE\Classes\.%%e"
    )
    CALL :delete_reg_value "HKLM\SOFTWARE\Classes\%%efile" "NeverShowExt" "HKCR\%%efile /v NeverShowExt"
)
IF "X!opt_known_ext!"=="XALL_USERS" (
    CALL :prepare_sids
    FOR %%i IN (!g_sids!) DO (
        ECHO SID %%i
        reg add "HKU\%%i\%ADVANCED_REG_SUBKEY%" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul || (
            CALL :show_reg_write_error "Explorer\Advanced /v HideFileExt"
        )
        FOR %%e IN (exe com scr bat cmd pif) DO (
            CALL :delete_reg_key "HKU\%%i\Software\Classes\.%%e" "HKU\*\Software\Classes\.%%e"
            CALL :delete_reg_key "HKU\%%i\Software\Classes\%%efile" "HKU\*\Software\Classes\%%efile"
        )
    )
)

:main_shortcut_icon
IF "X!opt_shortcut_icon!"=="XSKIP" GOTO main_all_drives
IF NOT "X!opt_shortcut_icon!"=="XDEFAULT" (
    ECHO.
    ECHO [shortcut-icon]
    ECHO �Ҧ�����!BIG5_AE7C!�ɮ׳������b�Y���p�ϥܡA�ר�O���V�����ɪ���!BIG5_AE7C!�C�ѩ�!BIG5_AE7C!�����ɦW�`�Q
    ECHO ���ð_�ӡA�ϥΪ̥u��z�L�b�Y���ϥܨӿ�{��!BIG5_AE7C!�ɡC
    ECHO �ڭ̱N�_��`������!BIG5_AE7C!�ɮ����� .lnk �P .pif ���b�Y�ϥܡC���G�����O�i�H���V������
    ECHO ���C�p�G�z���ۭq����!BIG5_AE7C!�b�Y�ϥܡA�b��!BIG5_B77C!�ϥΦۭq���ϥܡC
    ECHO �]�o�O�����]�w�C!BIG5_A15E!
    CALL :continue_prompt || GOTO main_all_drives
)
FOR %%e IN (lnk pif) DO (
    CALL :delete_reg_key "HKCU\Software\Classes\.%%e" "HKCU\Software\Classes\.%%e"
    CALL :delete_reg_key "HKCU\Software\Classes\%%efile" "HKCU\Software\Classes\%%efile"
    reg add "HKLM\SOFTWARE\Classes\.%%e" /ve /t REG_SZ /d "%%efile" /f >nul || (
        CALL :show_reg_write_error "HKLM\SOFTWARE\Classes\%%e"
    )
    reg add "HKLM\SOFTWARE\Classes\%%efile" /v "IsShortcut" /t REG_SZ /f >nul || (
        CALL :show_reg_write_error "HKCR\%%efile /v IsShortcut"
    )
)
IF "X!opt_shortcut_icon!"=="XDEFAULT" (
    CALL :delete_reg_value %SHELL_ICON_REG_KEY% "29" "Explorer\Shell Icons /v 29"
)

:main_all_drives
ECHO.
ECHO �{�b�ڭ̱N�B�z�Ҧ��Ϻо����ڥؿ��C
ECHO �д��J�Ҧ����c�N�n��v�T���x�s�˸m�A�]�A USB �H���СB�~���w�СB�O�Хd�BPDA�B��
ECHO �z������P�Ʀ�۾��C�p�G�z�� CD- �� DVD-RW ���Цb���о��̡A��ĳ�z�h�X���̡A�H�K
ECHO �~�ҰʿN�����ʧ@�C
PAUSE

IF NOT "X!opt_symlinks!"=="XSKIP" (
    ECHO.
    ECHO [symlinks]
    ECHO �b Windows Vista ����ANTFS �ɮרt�Τ䴩�u�Ÿ��s���v^(Symbolic link^)�C�Ÿ��s���O
    ECHO �@�دS���ɮסA�\��������!BIG5_AE7C!�ɡA�]�a����!BIG5_AE7C!���b�Y�ϥܡA���O�Ÿ��s���ݩ��ɮרt��
    ECHO ���\��A�ӥB���ݱa�����ɦW�C���Ǵc�N�n��!BIG5_B77C!�إ߫��V�]�c�N!BIG5_A15E!�����ɪ��Ÿ��s���A�H
    ECHO ���F�ϥΪ̥h�I�����̡C
    ECHO �ڭ̱N�R���ڥؿ����Ҧ����V�ɮס]�D�ؿ�!BIG5_A15E!���Ÿ��s���C
    CALL :continue_prompt || SET opt_symlinks=SKIP
)
IF NOT "X!opt_attrib!"=="XSKIP" (
    ECHO.
    ECHO [attrib]
    ECHO ���ɮצ��]�w�u���áv�Ρu�t�Ρv�ݩʡA���̴N�w�]��!BIG5_B77C!�b Windows �ɮ��`�ީ� DIR �R
    ECHO �O����ܡC���Ǵc�N�n��!BIG5_B77C!�����ɮסA�ò��ͬۦP�W�٪������ɡ]�άO���V�����ɪ���
    ECHO !BIG5_AE7C!!BIG5_A15E!�A�H���F�ϥΪ̥h�I�����̡C�]�c�N�n��ä�!BIG5_B77C!�u���R�����ɮסA���M�R���ɮ׮ɪ�
    ECHO �X���ϺЪŶ��ܮe���ް_�ϥΪ̩Ψ��r�n�骺�`�N�C!BIG5_A15E!
    ECHO ���F�w���u�����@�~�t���ɮסA�ڭ̱N�Ѱ��ڥؿ����Ҧ��ɮת��u���áv�P�u�t�Ρv��
    ECHO �ʡC�o�_��Ҧ��Q�c�N�n�鵹���ê��ɮס]�P�ɦ��i����ܴc�N�n���ɮץ���!BIG5_A15E!�C
    CALL :continue_prompt || SET opt_attrib=SKIP
)
IF NOT "X!opt_shortcuts!"=="XSKIP" (
    ECHO.
    ECHO [shortcuts]
    ECHO �ڭ̱N�R���ڥؿ����Ҧ� .lnk �P .pif �ɮ���������!BIG5_AE7C!�C
    CALL :continue_prompt || SET opt_shortcuts=SKIP
)
IF NOT "X!opt_folder_exe!"=="XSKIP" (
    ECHO.
    ECHO [folder-exe]
    ECHO ���Ǵc�N�n��!BIG5_B77C!���ø�Ƨ��A�ò��ͬۦP�W�٪������ɡA�q�`�P�ɱa�۸�Ƨ���
    ECHO �ܡA�H���F�ϥΪ̥h�I�����̡C
    ECHO �ڭ̱N�R���ڥؿ����Ҧ��P��Ƨ��ۦP�W�٪������ɡC!BIG5_B77C!�R�����ɮ������� .com, .exe
    ECHO �P .scr�C
    ECHO ĵ�i�G�o�i��!BIG5_B77C!�R����X�k�����ε{���A�Y���ü{�A�и��L���B�J�C
    CALL :continue_prompt || SET opt_folder_exe=SKIP
)
IF NOT "X!opt_files!"=="XSKIP" (
    ECHO.
    ECHO [files]
    ECHO ���Ǵc�N�n��!BIG5_B77C!�إ� autorun.inf �ɮסA�Ϧۤv�b�|������ AutoRun ���q���̦۰ʳQ��
    ECHO ��C���F���о��H�~�A�䥦�Ϻо��������ӧt���W�� autorun.inf ���ɮסC
    ECHO �ڭ̱N�R�����̡C
    CALL :continue_prompt || SET opt_files=SKIP
)
IF "X!opt_files!"=="XSKIP" (
    SET opt_mkdir=SKIP
)
IF NOT "X!opt_mkdir!"=="XSKIP" (
    ECHO.
    ECHO [mkdir]
    ECHO �R�� autorun.inf �ɮ׫�A���F�קK�c�N�n�魫�s�إߥ��A�ڭ̱N�إ߬ۦP�W�٪����å�
    ECHO ���A���ؿ��ϥΪ̬ݤ���A���i�z�Z�c�N�n��A���D�c�N�n�馳��O�R�����A�_�h�Ϻо�
    ECHO �N��!BIG5_B77C!�A�� AutoRun �P�V�C
    CALL :continue_prompt || SET opt_mkdir=SKIP
)

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
        ECHO �Ϻ� %%d�G
        REM Symlinks have to be handled first because we can't guarantee that
        REM user's 'attrib' utility supports '/L' (don't follow symlinks).
        IF NOT "X!opt_symlinks!"=="XSKIP" CALL :delete_symlinks
        REM :clear_files_attrib must be done before deleting anything, or DEL
        REM refuses to delete files with certain attributes.
        IF NOT "X!opt_attrib!"=="XSKIP" CALL :clear_files_attrib
        IF NOT "X!opt_shortcuts!"=="XSKIP" CALL :delete_shortcuts
        IF NOT "X!opt_folder_exe!"=="XSKIP" CALL :delete_folder_exes
        IF NOT "X!opt_files!"=="XSKIP" (
            FOR %%f IN (autorun.inf) DO (
                CALL :file_to_directory %%f
            )
        )
    )
)
ECHO.
ECHO ���������C�Ы����N���������{���C
PAUSE >nul
GOTO main_end

:main_help
ECHO.
ECHO   --help                   ��ܦ�����
ECHO   --no-restart             �����s�Ұʸ}���]�w�]!BIG5_B77C!�b������R�O�B�̵{���� AutoRun
ECHO                            �ɭ��s�Ұ�!BIG5_A15E!
ECHO   --skip-cmd-autorun       ���R���R�O�B�̵{���� AutoRun �n����
ECHO   --all-users-cmd-autorun  �R��*�Ҧ��ϥΪ�*�� cmd.exe AutoRun�]�w�]���i��!BIG5_A15E!
ECHO   --no-inf-mapping         ������ autorun.inf ����R
ECHO   --skip-mountpoints2      ���M�z MountPoints2 �n�����X�]�֨�!BIG5_A15E!
ECHO   --skip-known-ext         ����ܤw���ɮ����������ɦW
ECHO   --all-users-known-ext    *�Ҧ��ϥΪ�*����ܤw���ɮ����������ɦW�]�w�]���i��!BIG5_A15E!
ECHO   --skip-shortcut-icon     ���_�챶!BIG5_AE7C!�ɮת��b�Y�ϥ�
ECHO   --default-shortcut-icon  �����ۭq����!BIG5_AE7C!�ϥܨèϥΨt�ιw�]�ϥ�
ECHO �H�U�{�ǬO�M�Φb�Ҧ��Ϻо����ڥؿ��G
ECHO   --keep-symlinks          ���R���Ÿ��s�� ^(symbolic link^)
ECHO   --keep-attrib            �O�d�Ҧ��ɮת��u���áv�B�u�t�Ρv�ݩ�
ECHO   --keep-shortcuts         ���R����!BIG5_AE7C!�ɮס].lnk �P .pif!BIG5_A15E!
ECHO   --keep-folder-exe        ���R���P��Ƨ��ۦP�W�٪�������
ECHO   --keep-files             ���R�� autorun.inf �Ψ䥦�i��c�N���ɮ�
ECHO   --no-mkdir               ���b�R���ɮ׫�إߥؿ�
GOTO main_end

:main_restart
ECHO �b���� cmd.exe ���۰ʰ��� ^(AutoRun^) �R�O�U�A���s�Ұʥ��{��...
cmd /d /c "%0 --no-restart !args!" && GOTO main_end
ECHO ���s�Ұʮɵo�Ϳ��~�C�ХH�U�C�R�O�ӭ��s���楻�}���]�`�N '/d' �P '--no-restart'>&2
ECHO �ﶵ!BIG5_A15E!�G>&2
ECHO cmd /d /c ^"%0 --no-restart !args!^">&2
PAUSE
GOTO :EOF

:main_end
ENDLOCAL
EXIT /B 0

REM ---------------------------------------------------------------------------
REM SUBROUTINES

REM Prompts user to continue or skip.
REM @return 0 if user says to continue, or 1 if says to skip
:continue_prompt
    REM Note: If the user answers empty string after a "SET /P", The variable
    REM is kept the previous value and NOT set to the empty string.
    SET prompt=
    SET /P prompt="�Ы� Enter ���~��A�άO��J 'skip' ���L���B�J�G"
    IF "X!prompt!"=="X" EXIT /B 0
    IF /I "X!prompt!"=="XY" EXIT /B 0
    IF /I "X!prompt!"=="XSKIP" EXIT /B 1
    GOTO continue_prompt
GOTO :EOF

REM Displays a (generic) error message for any write error in registry.
REM (add key, delete key, add value, etc.)
REM @param %1 Short name about the registry key or value.
:show_reg_write_error
    ECHO �ק�n���ɵo�Ϳ��~�G"%~1">&2
    IF NOT "X!g_has_error_displayed!"=="X1" (
        SET g_has_error_displayed=1
        ECHO �z�i��ݭn�Ψt�κ޲z�����v�����s���榹�{���C>&2
        PAUSE
    )
GOTO :EOF

REM Prepares g_sids global variable (list of all user SIDs on the computer).
:prepare_sids
    IF NOT "X!g_sids!"=="X" GOTO :EOF
    FOR /F "usebackq delims=" %%k IN (`reg query HKU 2^>nul`) DO (
        REM 'reg' outputs junk lines, make sure the line truly represents a
        REM user and not a Classes key.
        SET "key=%%~k"
        IF /I "!key:~0,11!"=="HKEY_USERS\" (
            IF /I NOT "!key:~-8!"=="_Classes" (
                SET g_sids=!g_sids! !key:~11!
            )
        )
    )
GOTO :EOF

REM Deletes a registry key (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Short hint of the key, displayed in error messages
REM @return 0 if key doesn't exist or is deleted successfully, or 1 on error
:delete_reg_key
    REM Must query the whole key. 'reg' in Windows 2000/XP returns failure on a
    REM "value not set" default with '/ve', while in Vista it returns success.
    reg query "%~1" >nul 2>nul || EXIT /B 0
    reg delete "%~1" /f >nul && EXIT /B 0
    CALL :show_reg_write_error %2
    EXIT /B 1
GOTO :EOF

REM Cleans a registry key (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Short hint of the key, displayed in error messages
REM @return 0 if key doesn't exist or is cleaned successfully, or 1 on error
:clean_reg_key
    CALL :delete_reg_key %1 %2 || EXIT /B 1
    REM Create a dummy value so that "reg add" won't affect the default value
    REM of the key.
    reg add "%~1" /v "dummy" /f >nul 2>nul || EXIT /B 1
    reg delete "%~1" /v "dummy" /f >nul 2>nul
GOTO :EOF

REM Deletes a non-default registry value (if it exists).
REM @param %1 Key name, including root key
REM @param %2 Value name
REM @param %3 Short hint of the entry, displayed in error messages
REM @return 0 if value doesn't exist or is deleted, or 1 on error
:delete_reg_value
    reg query "%~1" /v "%~2" >nul 2>nul || EXIT /B 0
    reg delete "%~1" /v "%~2" /f >nul && EXIT /B 0
    CALL :show_reg_write_error %3
    EXIT /B 1
GOTO :EOF

REM Checks if the file is in one of the list of files to keep.
REM @param %1 Category
REM @param %2 File to check
REM @return 0 (true) if the file is in the list
:is_file_to_keep
    SET list=
    IF "X%1"=="XSYMLINK"   SET list=!KEEP_SYMLINK_FILES!
    IF "X%1"=="XHS_ATTRIB" SET list=!KEEP_HS_ATTRIB_FILES!
    IF "X%1"=="XH_ATTRIB"  SET list=!KEEP_H_ATTRIB_FILES!
    IF "X%1"=="XS_ATTRIB"  SET list=!KEEP_S_ATTRIB_FILES!
    IF "X%1"=="XEXECUTE"   SET list=!KEEP_EXECUTE_FILES!
    FOR %%i IN (%list%) DO (
        IF /I "X%~2"=="X%%~i" EXIT /B 0
        IF /I "X%~2\"=="X%%~i" (
            ECHO.%~a2 | find "d" >nul 2>nul && EXIT /B 0
        )
    )
    EXIT /B 1
GOTO :EOF

REM Deletes a specified symlink.
REM @param %1 Symlink name
:delete_symlink
    REM 'attrib' without '/L' follows symlinks so can't be used here, but
    REM "DEL /F /A:<attrib>" can.
    REM The exit code of DEL command is unreliable.
    SET attr=
    ECHO.%~a1 | find "h" >nul 2>nul && SET attr=h
    ECHO.%~a1 | find "s" >nul 2>nul && SET attr=!attr!s
    DEL /F /A:!attr! "%~1"
GOTO :EOF

REM Deletes all file symlinks in current directory.
REM Note that this function will have problems with files with newlines ('\n')
REM in their filenames.
:delete_symlinks
    REM Directory symlinks/junctions are harmless. Leave them alone.
    REM DIR command in Windows 2000 supports "/A:L", but displays symlinks
    REM (file or directory) as junctions. Undocumented feature.
    REM The "2^>nul" is to suppress the "File not found" output by DIR command.
    FOR /F "usebackq delims=" %%f IN (`DIR /A:L-D /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep SYMLINK "%%~f" && (
            ECHO ���F�w���]���A���L�Ÿ��s�� "%%~f"
        ) || (
            ECHO �R���Ÿ��s�� "%%~f"
            CALL :delete_symlink "%%~f"
        )
    )
    REM Note when handling directory links/junctions:
    REM If "dirlink" is a directory link, "DEL dirlink" removes all files in
    REM the target directory (DANGEROUS), "RMDIR dirlink" (with or without
    REM '/S') removes the symlink without touching anything in the target
    REM directory (SAFE).
GOTO :EOF

REM Clears hidden and system attributes of all files in current directory.
REM Note that this function will have problems with files with newlines ('\n')
REM in their filenames.
:clear_files_attrib
    REM 'attrib' refuses to clear either H or S attribute for files with both
    REM attributes set. Must clear both simultaneously.
    REM The exit code of 'attrib' is unreliable.
    REM The "2^>nul" is to suppress the "File not found" output by DIR command.
    FOR /F "usebackq delims=" %%f IN (`DIR /A:HS /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep HS_ATTRIB "%%~f" && (
            ECHO ���F�w���]���A���L�ɮ� "%%~f"�]����+�t���ݩ�!BIG5_A15E!
        ) || (
            ECHO �Ѱ�����+�t���ݩ� "%%~f"
            attrib -H -S "%%~f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:H-S /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep H_ATTRIB "%%~f" && (
            ECHO ���F�w���]���A���L�ɮ� "%%~f"�]�����ݩ�!BIG5_A15E!
        ) || (
            ECHO �Ѱ������ݩ� "%%~f"
            attrib -H "%%~f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:S-H /B /O:N 2^>nul`) DO (
        CALL :is_file_to_keep S_ATTRIB "%%~f" && (
            ECHO ���F�w���]���A���L�ɮ� "%%~f"�]�t���ݩ�!BIG5_A15E!
        ) || (
            ECHO �Ѱ��t���ݩ� "%%~f"
            attrib -S "%%~f"
        )
    )
GOTO :EOF

REM Deletes .lnk and .pif shortcut files in current directory.
:delete_shortcuts
    ECHO ���b�R�� .lnk �P .pif ��!BIG5_AE7C!...
    DEL /F *.lnk
    DEL /F *.pif
GOTO :EOF

REM Deletes all executable files (.com, .exe and .scr) that carry the same name
REM as a folder in current directory.
:delete_folder_exes
    REM Note: .bat and .cmd are self-executable, but their icons are static, so
    REM leave them alone.
    FOR /F "usebackq delims=" %%d IN (`DIR /A:D /B /O:N 2^>nul`) DO (
        FOR /F "usebackq delims=" %%e IN (
            `DIR /A:-D /B /O:N "%%~d.com" "%%~d.exe" "%%~d.scr" 2^>nul`
        ) DO (
            CALL :is_file_to_keep EXECUTE "%%~e" && (
                ECHO ���F�w���]���A���L�ɮ� "%%~e"
            ) || (
                ECHO �R�� "%%~e"
                DEL /F "%%~e"
            )
        )
    )
GOTO :EOF

REM Force deletes a file and creates a directory with the same name.
REM @param %1 File name to be converted into a directory
REM @return 0 if directory exists or is created successfully, or 1 on error
:file_to_directory
    IF EXIST %1 (
        ECHO.%~a1 | find "d" >nul 2>nul && (
            REM File exists and is a directory. Keep it.
            attrib +R +H +S "%~1"
            EXIT /B 0
        )
        ECHO �R�� "%~1"
        DEL /F "%~1"
        IF EXIST %1 EXIT /B 1
    )
    IF "X!opt_mkdir!"=="XSKIP" EXIT /B 0
    CALL :make_directory %1
GOTO :EOF

REM Creates a directory and writes a file named DONT_DEL.txt inside it.
REM @param %1 Directory name
REM @return 0 if directory is created successfully (despite the file within)
:make_directory
    MKDIR "%~1" || (
        ECHO �إߥؿ��ɵo�Ϳ��~�G"%~1">&2
        EXIT /B 1
    )
    REM Don't localize the text below. I want this file to be readable despite
    REM the encoding the user's system is in, and it's difficult to convert
    REM character encodings in shell.
    (
        ECHO This directory, "%~1", is to protect your disk from injecting a
        ECHO malicious %1 file.
        ECHO Your disk may still carry the USB or AutoRun malware, but it will NOT be
        ECHO executed anymore.
        ECHO Please do not remove this directory. If you do, you'll lose the protection.
        ECHO.
        ECHO This directory is generated by 'usb_vaccine.cmd'. Project website:
        ECHO ^<https://github.com/Explorer09/usb_vaccine^>
    ) >"%~1\DONT_DEL.txt"
    attrib +R +H +S "%~1"
    EXIT /B 0
GOTO :EOF

REM ---------------------------------------------------------------------------
:EOF
