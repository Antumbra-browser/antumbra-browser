# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# NSIS branding defines for Antumbra builds.
# BrandShortName is defined by defines.nsi.in from MOZ_APP_DISPLAYNAME; do not
# define it here or the installer build fails with "already defined".

!define BrandFullNameInternal "Antumbra"
!define BrandFullName         "Antumbra Browser"
!define CompanyName           "antumbra"
!define URLInfoAbout          "https://antumbrabrowser.org"
!define HelpLink              "https://antumbrabrowser.org/help"

!define URLStubDownloadX86 "https://antumbrabrowser.org/download?os=win"
!define URLStubDownloadAMD64 "https://antumbrabrowser.org/download?os=win64"
!define URLStubDownloadAArch64 "https://antumbrabrowser.org/download?os=win64-aarch64"
!define URLManualDownload "https://antumbrabrowser.org/download"
!define URLSystemRequirements "https://antumbrabrowser.org/system-requirements"
!define Channel "release"

# No code-signing identity yet; see BRANDING.md launch checklist and
# ROADMAP.md milestone 2 for the Windows signing plan.
!define CertNameDownload   ""
!define CertIssuerDownload ""

# Dialog units are used so the UI displays correctly with the system's DPI
# settings.
!define PROFILE_CLEANUP_LABEL_TOP "35u"
!define PROFILE_CLEANUP_LABEL_LEFT "0"
!define PROFILE_CLEANUP_LABEL_WIDTH "100%"
!define PROFILE_CLEANUP_LABEL_HEIGHT "80u"
!define PROFILE_CLEANUP_LABEL_ALIGN "center"
!define PROFILE_CLEANUP_CHECKBOX_LEFT "center"
!define PROFILE_CLEANUP_CHECKBOX_WIDTH "100%"
!define PROFILE_CLEANUP_BUTTON_LEFT "center"
!define INSTALL_BLURB_TOP "137u"
!define INSTALL_BLURB_WIDTH "60u"
!define INSTALL_FOOTER_TOP "-48u"
!define INSTALL_FOOTER_WIDTH "250u"
!define INSTALL_INSTALLING_TOP "70u"
!define INSTALL_INSTALLING_LEFT "0"
!define INSTALL_INSTALLING_WIDTH "100%"
!define INSTALL_PROGRESS_BAR_TOP "112u"
!define INSTALL_PROGRESS_BAR_LEFT "20%"
!define INSTALL_PROGRESS_BAR_WIDTH "60%"
!define INSTALL_PROGRESS_BAR_HEIGHT "12u"

!define PROFILE_CLEANUP_CHECKBOX_TOP_MARGIN "20u"
!define PROFILE_CLEANUP_BUTTON_TOP_MARGIN "20u"
!define PROFILE_CLEANUP_BUTTON_X_PADDING "40u"
!define PROFILE_CLEANUP_BUTTON_Y_PADDING "4u"

# Font settings that can be customized for each channel
!define INSTALL_HEADER_FONT_SIZE 28
!define INSTALL_HEADER_FONT_WEIGHT 400
!define INSTALL_INSTALLING_FONT_SIZE 28
!define INSTALL_INSTALLING_FONT_WEIGHT 400

# UI Colors matching the --void and --daylight palette from BRANDING.md
!define COMMON_TEXT_COLOR 0xE8ECF1
!define COMMON_BACKGROUND_COLOR 0x100D0B
!define INSTALL_INSTALLING_TEXT_COLOR 0xE8ECF1
