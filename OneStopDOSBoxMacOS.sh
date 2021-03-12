#!/bin/zsh

# One-script macOS solution to create a build-environment for DOSBox
# by downloading and installing the required libraries, then building
# dynamic-linked or static linked-versions (or both) and creating
# an macOS application containing the unix executable. 
# All details and knowledge provided by Dominus at vogons.org!!

# specify folder for creating the build environment;
# this can be any folder where you have write permission;
# the folder will be created if it doesn't exist
BUILDFOLDER="$HOME/DBBuild"

# specify default folder containing DOSBox source below:
# this option only used when getting source or building executables
DOSBOXFOLDER="$BUILDFOLDER/dosbox"

# specify name for application bundle (no ".app", just the name)
APPNAME="MyDOSBox"

# set BUILDENV to 1 to be prompted to create the build envionment
BUILDENV=1
# set DOWNLOAD to 1 to download the installers for the build environment
DOWNLOAD=1
# set GETDOSBOX to 1 to download DOSBox source
GETDOSBOX=1
# set BUILDDOSBOX to 1 to enable the option to build executables
BUILDDOSBOX=1

###--------------------------------- # Storage for things to do later
 
### Example of block to copy files from one directory-tree into another
### From: http://stackoverflow.com/questions/3331348

#download="/folder/of/extracted/zip/archive"
#target="$DOSBOXFOLDER"
#find "${download}" -name "*" | while read -r file
#do
#    mv "${file}" "${target}"
#done

###--------------------------------- # Parameters for directory or uninstall 

UNINST=0
PATHPARAM=0

if [[ $# -eq 0 ]] ; then
    echo  # Save for future use
else
	# Test for "uninstall" or path hame
    if [ $1 = "uninstall" ] || [ $1 = "--uninstall" ] || [ $1 = "-uninstall" ] || [ $1 = "-u" ] ; then
	    UNINST=1
		BUILDENV=1			# override setting to 0 above
	elif [ $1 = "help" ] || [ $1 = "--help" ] || [ $1 = "-help" ] || [ $1 = "-h" ] || [ $1 = "-?" ] ; then
		echo '----------------------------------------------------------------' 
		echo 'OneStopDOSBoxMacOS.sh downloads libraries to create a build environment'
		echo 'for DOSBox, then downloads and/or builds DOSBox from source code'
		echo 'Optional parameters:'
		echo '  /path/to/folder/for/dosbox (non-existent directory will be created)'
		echo '  uninstall (uninstalls previously-installed libraries)'
		echo '----------------------------------------------------------------'  
		exit
    else
		PATHPARAM=1
    fi
fi
# echo $FOLDER
#exit

if [ $UNINST = 0 ] ; then
	INSTSTR="Install"
else
	INSTSTR="Uninstall"
fi

###--------------------------------- #  Functions 

# error handling from Dominus
DIE=0
function error_quit
{
echo -e "\033[1;31m **Error** line #${1:-"Unknown Error"}\033[0m" 1>&2
exit 1
}

mfile="Makefile"
function distclean () {
	if [ -f "$mfile" ] ; then
		make distclean >/dev/null
	fi
}

###--------------------------------- # Test for Xcode and Xcode command line tools

if [ $UNINST != 1 ] ; then

if open -Ra "Xcode" ; then
	echo "Xcode found."
	echo "If you have not already run Xcode at least once, exit and do so now."
else
	echo
	echo "Xcode must be installed from the App Store and run once. Exiting."
	exit
fi

if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
   test -d "${xpath}" && test -x "${xpath}" ; then
   		echo "Xcode command line tools installed"
else
		echo "Xcode command-line tools not found. Exiting."
		echo "To install the tools, enter the following command at the terminal:"
		echo "xcode-select --install" 
		echo 
		exit 
fi

fi

###--------------------------------- #  Required options and exports

OPT=' -O2 -m64 -msse -msse2 '
SDK=' -mmacosx-version-min=10.12'
export MACOSX_DEPLOYMENT_TARGET=10.12
export PATH=$BUILDFOLDER/x86_64/bin/:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
export CC="/usr/bin/clang"
export CXX="/usr/bin/clang++"
export CPPFLAGS='-I'$BUILDFOLDER'/x86_64/include '$SDK
export CFLAGS='-I'$BUILDFOLDER'/x86_64/include '$SDK' '$OPT
export CXXFLAGS='-I'$BUILDFOLDER'/x86_64/include '$SDK' '$OPT
export LDFLAGS='-L'$BUILDFOLDER'/x86_64/lib '$SDK' '$OPT
export PKG_CONFIG_PATH="$BUILDFOLDER/x86_64/lib/pkgconfig"
export PKG_CONFIG=$BUILDFOLDER/x86_64/bin/pkg-config

###--------------------------------- # Start prompting

echo
echo In the prompts below, you must type y or Y to choose Yes
echo You may skip any step by pressing Enter or n or N.
if [ $BUILDENV = 1 ] ; then 		## this begins the show env block prompt
	if [ $UNINST != 1 ] ; then
		echo You should only need to create the build environment once.
	fi 
###--------------------------------- # To build or not to build the environment

echo
# which prompt to use: create or remove?
if [ $UNINST != 1 ] ; then 
	BUILDSTR="Create the build environment (skip this step after creating) (y/N)? "
else
	BUILDSTR="Uninstall the libraries installed in the build environment (y/N)? "
fi
#ask the question defined above
read "?$BUILDSTR"
echo   
if [[ $REPLY =~ ^[Yy]$ ]] ; then		## this begins the create-environment block

###--------------------------------- #  Create Development folder when needed 

if [ $UNINST != 1 ] ; then

echo "Making $BUILDFOLDER (if it doesn't exist)"
mkdir -p $BUILDFOLDER
echo "Changing to $BUILDFOLDER"
echo 
cd $BUILDFOLDER

###--------------------------------- # Install autoconf

if command -v autoconf > /dev/null 2>&1; then
  echo "Autoconf is available to this script. You may reinstall if you want."
else
  echo "Autoconf is not available to this script."
fi

read "?$INSTSTR autoconf (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
ACVER="2.69"
if [ $UNINST != 1 ] ; then
	echo "Downloading autoconf $ACVER ..."
	mkdir -p $BUILDFOLDER/autoconf-$ACVER
	if [ $DOWNLOAD = 1 ] ; then
	    curl -OL http://gnu.mirror.globo.tech/autoconf/autoconf-$ACVER.tar.gz
	    tar -xzf autoconf-$ACVER.tar.gz -C $BUILDFOLDER/
	    rm autoconf-$ACVER.tar.gz
	fi
	cd $BUILDFOLDER/autoconf-$ACVER
	distclean
	./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
	make -j9 -s >/dev/null 
	make install >/dev/null    
	make clean  >/dev/null
	echo
	echo "Installed autoconf $ACVER"
else
	cd $BUILDFOLDER/autoconf-$ACVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/autoconf-$ACVER
    rmdir $BUILDFOLDER/x86_64/share/autoconf/m4sugar
    rmdir $BUILDFOLDER/x86_64/share/autoconf/autotest
    rmdir $BUILDFOLDER/x86_64/share/autoconf/autoscan
    rmdir $BUILDFOLDER/x86_64/share/autoconf/Autom4te
    rmdir $BUILDFOLDER/x86_64/share/autoconf/autoconf
    rmdir $BUILDFOLDER/x86_64/share/autoconf
fi
echo && echo

fi

###--------------------------------- # Install automake

if command -v automake > /dev/null 2>&1; then
  echo "Automake is available to this script. You may reinstall if you want."
else
  echo "Automake is not available to this script."
fi

read "?$INSTSTR automake (y/N)? "
echo  
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
AMVER="1.15"
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/automake-$AMVER
if [ $DOWNLOAD = 1 ] ; then
	echo "Downloading automake $AMVER ..."
    curl -OL http://ftpmirror.gnu.org/automake/automake-$AMVER.tar.gz
    tar -xzf automake-$AMVER.tar.gz -C $BUILDFOLDER
    rm automake-$AMVER.tar.gz
fi
cd $BUILDFOLDER/automake-$AMVER
distclean
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null
make install >/dev/null
make clean  >/dev/null
echo
echo "Installed automake $AMVER"
else
	cd $BUILDFOLDER/automake-$AMVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/automake-$AMVER
    rmdir $BUILDFOLDER/x86_64/share/automake-$AMVER/am
    rmdir $BUILDFOLDER/x86_64/share/automake-$AMVER/Automake
    rmdir $BUILDFOLDER/x86_64/share/automake-$AMVER
    rmdir $BUILDFOLDER/x86_64/share/share/doc/automake
fi
echo && echo

fi

###--------------------------------- # Install libtool

if command -v libtool > /dev/null 2>&1; then
  echo "Libtool is available to this script. You may reinstall if you want."
else
  echo "Libtool is not available to this script."
fi

### can't uninstall libtool, so not offering the option yet...
if [ $UNINST != 1 ] ; then
read "?$INSTSTR libtool (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
LTVER="2.4.6"
mkdir -p $BUILDFOLDER/libtool-$LTVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL http://ftpmirror.gnu.org/libtool/libtool-$LTVER.tar.gz
    tar -xzf libtool-2.4.6.tar.gz -C $BUILDFOLDER
    rm libtool-$LTVER.tar.gz
fi
cd $BUILDFOLDER/libtool-$LTVER
make clean
ARGS=''
ARGS='F77=no FC=no GCJ=no --program-prefix=g'
./configure -q --prefix=$BUILDFOLDER/x86_64 
#### ${=ARGS}
make -j9 -s >/dev/null
make install >/dev/null
make clean >/dev/null
ARGS=''
echo
echo "Installed libtool $LTVER"
echo && echo
fi

fi

###--------------------------------- # Install pkgconfig

if command -v pkg-config > /dev/null 2>&1; then
  echo "pkgconfig is available to this script. You may reinstall if you want."
else
  echo "pkgconfig is not available to this script."
fi

read "?$INSTSTR pkgconfig (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
PCVER="0.29.2"
if [ $UNINST = 0 ] ; then
mkdir -p $BUILDFOLDER/pkg-config-$PCVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL https://pkg-config.freedesktop.org/releases/pkg-config-$PCVER.tar.gz
    tar -xzf pkg-config-$PCVER.tar.gz -C $BUILDFOLDER
    rm pkg-config-$PCVER.tar.gz
fi
cd $BUILDFOLDER/pkg-config-$PCVER
mkdir -p $BUILDFOLDER/x86_64/lib/pkgconfig
mkdir -p $BUILDFOLDER/x86_64/share/pkgconfig
distclean
ARGS=''
ARGS='--with-pc-path=$BUILDFOLDER/x86_64/share/pkgconfig --with-internal-glib --disable-silent-rules --disable-host-tool'
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null 
make install >/dev/null
make clean >/dev/null 
echo
echo "pkg-config installed $PCVER"
ARGS=''
export PKG_CONFIG_PATH="$BUILDFOLDER/x86_64/lib/pkgconfig"
else
	cd $BUILDFOLDER/pkg-config-$PCVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/pkg-config-$PCVER
    # rmdir $BUILDFOLDER/x86_64/lib/pkgconfig
    rmdir $BUILDFOLDER/x86_64/share/pkgconfig
    rmdir $BUILDFOLDER/x86_64/share/doc/pkg-config
fi

echo && echo

fi

###--------------------------------- # Install lzib

## belongs here?
export PKG_CONFIG_PATH="$BUILDFOLDER/x86_64/lib/pkgconfig"

# if pkg-config --libs zlib | grep -q 'was not found' > /dev/null 2>&1; then
# 	echo "zlib is not available to this script."
# else 
# 	echo "zlib is avaiable to this script. You may reinstall if you want."
# fi

read "?$INSTSTR zlib (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
ZLVER="1.2.11" 
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/zlib-$ZLVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL http://zlib.net/zlib-$ZLVER.tar.gz
    tar -xzf zlib-$ZLVER.tar.gz -C $BUILDFOLDER
    rm zlib-$ZLVER.tar.gz
fi
cd $BUILDFOLDER/zlib-$ZLVER
distclean
ARGS=""
./configure --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null 
make install >/dev/null 
make clean >/dev/null 
echo "Installed zlib $ZLVER"
else
	cd $BUILDFOLDER/zlib-$ZLVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/zlib-$ZLVER
fi
echo && echo

fi

###--------------------------------- # Install libogg

# if pkg-config --libs libogg | grep -q 'was not found' > /dev/null 2>&1; then
# 	echo "libogg is not available to this script."
# else 
# 	echo "libogg is avaiable to this script. You may reinstall if you want."
# fi

read "?$INSTSTR libogg (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
LOVER="1.3.4"
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/libogg-$LOVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL http://downloads.xiph.org/releases/ogg/libogg-$LOVER.tar.gz
    tar -xzf libogg-$LOVER.tar.gz -C $BUILDFOLDER
    rm libogg-$LOVER.tar.gz
fi
cd $BUILDFOLDER/libogg-$LOVER
distclean

rm libogg.patch

echo "Creating temporary patch file for libogg ..."

echo 'diff --git include/ogg/os_types.h include/ogg/os_types.h' > libogg.diff
echo 'index 4165bce..eb8a322 100644' >>libogg.diff
echo '--- include/ogg/os_types.h' >>libogg.diff
echo '+++ include/ogg/os_types.h' >>libogg.diff
echo '@@ -70,7 +70,7 @@' >>libogg.diff
echo '' >>libogg.diff
echo ' #elif (defined(__APPLE__) && defined(__MACH__)) /* MacOS X Framework build */' >>libogg.diff
echo '' >>libogg.diff 
echo '-#  include <sys/types.h>' >>libogg.diff
echo '+#  include <inttypes.h>' >>libogg.diff
echo '    typedef int16_t ogg_int16_t;' >>libogg.diff
echo '    typedef uint16_t ogg_uint16_t;' >>libogg.diff
echo '    typedef int32_t ogg_int32_t;' >>libogg.diff

echo && echo

echo "Applying temporary libogg patch ..."
patch -p0 -i libogg.diff ||  error dosbox patch
if [ "$?" = "0" ]; then
    echo "libogg patch succeeded."
else
	echo "libogg patch failed. Exiting"
    exit
fi

ARGS=""
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null
make install >/dev/null
make clean  >/dev/null
echo
echo "Installed libogg #$LOVER"
else
	cd $BUILDFOLDER/libogg-$LOVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/libogg-$LOVER
    rmdir $BUILDFOLDER/x86_64/include/ogg
    rmdir $BUILDFOLDER/x86_64/share/doc/libogg/libogg
    rmdir $BUILDFOLDER/x86_64/share/doc/libogg
fi
echo && echo

fi

###--------------------------------- # Install libvorbis

read "?$INSTSTR libvorbis (y/N)? " 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
LVVER="1.3.7"
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/libvorbis-$LVVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL http://downloads.xiph.org/releases/vorbis/libvorbis-$LVVER.tar.gz
    tar -xzf libvorbis-$LVVER.tar.gz -C $BUILDFOLDER
    rm libvorbis-$LVVER.tar.gz
fi
cd $BUILDFOLDER/libvorbis-$LVVER
distclean
ARGS=""
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS} --disable-oggtest  ### ask Dominus
make -j9 -s >/dev/null
make install >/dev/null
make clean >/dev/null
echo
echo "Installed libvorbis $LVVER"
else
	cd $BUILDFOLDER/libvorbis-$LVVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/libvorbis-$LVVER
    rmdir $BUILDFOLDER/x86_64/include/vorbis
fi
echo && echo

fi

###--------------------------------- # Install libpng

read "?$INSTSTR libpng (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
LPVER="1.6.37"
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/libpng-$LPVER
if [ $DOWNLOAD = 1 ] ; then
    cd $BUILDFOLDER
    curl -OL http://prdownloads.sourceforge.net/libpng/libpng-$LPVER.tar.gz
    tar -xzf libpng-$LPVER.tar.gz -C $BUILDFOLDER
    rm libpng-$LPVER.tar.gz
fi
cd $BUILDFOLDER/libpng-$LPVER
unset CFLAGS
ARGS=""
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null 
make install >/dev/null 
make clean >/dev/null
export CFLAGS='-I'$BUILDFOLDER'/x86_64/include '$SDK' '$OPT 
echo
echo "Installed libpng $LPVER"
else
	cd $BUILDFOLDER/libpng-$LPVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/libpng-$LPVER
    rmdir $BUILDFOLDER/x86_64/include/libpng16
fi
echo && echo

fi

###--------------------------------- # Install dylibbundler

if command -v $BUILDFOLDER/macdylibbundler-master/dylibbundler > /dev/null 2>&1; then
  echo "dylibbundler is available to this script. You may reinstall if you want."
else
  echo "dylibbundler is not available to this script."
fi

read "?$INSTSTR dylibbundler (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/macdylibbundler-master
if [ $DOWNLOAD = 1 ] ; then
    curl -OL https://github.com/auriamg/macdylibbundler/archive/master.zip
    tar -xzf master.zip -C $BUILDFOLDER
    rm master.zip
fi
cd $BUILDFOLDER/macdylibbundler-master
make clean
ARGS=""
make -j9 -s >/dev/null
echo
echo "Built dylibbundler" 
else
	cd $BUILDFOLDER/macdylibbundler-master
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/dylibbundler-master
	rmdir $BUILDFOLDER/x86_64/dylibbundler	  ## check this?
fi
echo && echo

fi

###--------------------------------- # Install SDL 1.2

read "?$INSTSTR SDL 1.2 (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items

if [ $UNINST != 1 ] ; then

if [ $DOWNLOAD=1 ] ; then 
	curl -OL https://github.com/libsdl-org/SDL-1.2/archive/main.zip
	tar -xzf main.zip -C $BUILDFOLDER
	rm main.zip
 fi

## fi

cd $BUILDFOLDER/SDL-1.2-main

# if [ $DOWNLOAD=1 ] ; then 
#    echo "Downloading patch file"
#    curl -o CoreAudio-SDL-1.2.diff -L https://bugzilla-attachments.libsdl.org/attachment.cgi?id=2272
#    echo "Patching SDL-1.2"
#    # patch -p1 -N < CoreAudio-SDL-1.2.diff ||  error CoreAudio patch
#    patch -p1 -N < CoreAudio-SDL-1.2.diff 
# fi

distclean
./autogen.sh >/dev/null
ARGS=''
ARGS='--enable-static --enable-joystick --enable-video-cocoa --enable-video-opengl --disable-video-x11 --without-x --disable-nasm'
echo "Now running configure"
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
echo "Now running make"
make clean >/dev/null
make -j9 -s >/dev/null 
make install >/dev/null 
make clean >/dev/null 
ARGS=''
echo
echo "Installed SDL 1.2"
cd $BUILDFOLDER

else
	cd $BUILDFOLDER/SDL-1.2-main
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/SDL-1.2-main
    rmdir $BUILDFOLDER/x86_64/include/SDL
fi

fi

echo

fi

###--------------------------------- # Install SDL_Sound

read "?$INSTSTR SDL_sound (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
SSVER="1.0.3"
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/SDL_sound-$SSVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL http://icculus.org/SDL_sound/downloads/SDL_sound-$SSVER.tar.gz
    tar -xzf SDL_sound-$SSVER.tar.gz -C $BUILDFOLDER
    rm SDL_sound-$SSVER.tar.gz
fi
cd $BUILDFOLDER/SDL_sound-$SSVER
distclean
ARGS=''
ARGS='--disable-mikmod --disable-modplug --disable-flac --disable-speex --disable-physfs --disable-smpeg --disable-sdltest'
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null
make install >/dev/null
make clean >/dev/null 
ARGS=''
echo
echo "Installed SDL_sound $SSVER"
else
	cd $BUILDFOLDER/SDL_sound-$SSVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/SDL_sound=$SSVER
    # rmdir $BUILDFOLDER/x86_64/include/SDL
fi
echo && echo

fi

###--------------------------------- # Install SDL_net

read "?$INSTSTR SDL_net (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

DOWNLOAD=$DOWNLOAD  #change to 1 or 0 to change download control for remaining items
SNVER="1.2.8"
if [ $UNINST != 1 ] ; then
mkdir -p $BUILDFOLDER/SDL_net-$SNVER
if [ $DOWNLOAD = 1 ] ; then
    curl -OL https://www.libsdl.org/projects/SDL_net/release/SDL_net-$SNVER.tar.gz
    tar -xzf SDL_net-$SNVER.tar.gz -C $BUILDFOLDER
    rm SDL_net-$SNVER.tar.gz
fi
cd $BUILDFOLDER/SDL_net-$SNVER
distclean
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
make -j9 -s >/dev/null
make install >/dev/null
make clean >/dev/null 
echo
echo "Installed SDL_net $SNVER"
else
	cd $BUILDFOLDER/SDL_net-$SNVER
	make uninstall >/dev/null
	cd ..
	rm -rf $BUILDFOLDER/SDL_net-$SNVER
    rmdir $BUILDFOLDER/x86_64/include/SDL
fi
echo && echo

fi

###---------------------------------- # end of separate builds

fi 	# this ends Create environment block

fi 	# this ends the show option to create environment block


###--------------------------------- # Download dosbox source code?

if [ $UNINST != 1 ] ; then    # start not-uninst block that contains get and build

if [ $PATHPARAM = 1 ] ; then

	if [ -d $1 ] ; then 
		FOLDER=$(cd $1; pwd)
		read "?Download and/or build dosbox in $FOLDER (y/N)? " 
		echo 
			if [[ $REPLY =~ ^[Yy]$ ]] ; then
				DOSBOXFOLDER=$1
    		else
    			exit
    		fi
    else
    	 read "?Create directory $1 (y/N)?"
    	 	if [[ $REPLY =~ ^[Yy]$ ]] ; then
				DOSBOXFOLDER=$1
                mkdir -p "$1"
                FOLDERNEW=1
                echo
			else
				exit
			fi
    fi

fi # end pathparam

if [ $GETDOSBOX = 1 ] ; then
	echo
	read "?Download latest dosbox source to $DOSBOXFOLDER (y/N)? " 
	echo 
	
	if [[ $REPLY =~ ^[Yy]$ ]] ; then
		if [ -d "$DOSBOXFOLDER" ] ; then
            if [ $FOLDERNEW !=1 ] ; then
                echo
                read "?First delete existing $DOSBOXFOLDER and its contents (y/N)? "
                echo 
                if [[ $REPLY =~ ^[Yy]$ ]] ; then
                    rm -rf $DOSBOXFOLDER
                fi
            fi
		fi  # end test folder is directory block
        
		mkdir -p $DOSBOXFOLDER
		rm -rf $TMPDIR/dosboxsource >/dev/null 2>&1
		mkdir -p $TMPDIR/dosboxsource/
		curl -OL http://source.dosbox.com/dosboxsvn.tgz
		tar -xzf dosboxsvn.tgz -C $TMPDIR/dosboxsource/
		rm dosboxsvn.tgz
		ditto $TMPDIR/dosboxsource/dosbox $DOSBOXFOLDER        # ditto not available on linux
		echo && echo
		
	fi # end test for reply yes

fi # end test getdosbox block

###-------------------------- # build dosbox, dynamic and/or static

if [ $BUILDDOSBOX = 1 ] ; then		# starts overall build block

echo
read "?Build dynamic-linked dosbox in $DOSBOXFOLDER (y/N)? " 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then

if [ -f "$DOSBOXFOLDER/src/dosbox.cpp" ] ; then	## checking for at least one source file
		echo Source folder seems to be correct.
	else
		echo
		echo Could not find source files in $DOSBOXFOLDER. Aborting.
		exit
fi

distclean

export CFLAGS='-I'$BUILDFOLDER'/x86_64/include '$SDK' '$OPT
cd $DOSBOXFOLDER
### autoheader -f 
### autoconf -f
### automake -f 
./autogen.sh
chmod +x ./configure
./configure -q --prefix=$BUILDFOLDER/x86_64 ${=ARGS}
	
make clean && make -j9 -s || {
DIE=1
error_quit "$(( $LINENO -2 )) : make failed."
}
echo && echo Dynamic-linked dosbox built in $DOSBOXFOLDER/src
echo

read "?Run dynamic-linked dosbox executable in $DOSBOXFOLDER/src (y/N)? " 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then
	cd ./src
    echo '[cpu]'>testdosbox.conf
    echo 'core=dynamic'>>testdosbox.conf
    echo '[autoexec]'>>testdosbox.conf
    echo 'config -get cpu'>>testdosbox.conf
    ./dosbox -conf ./testdosbox.conf
	cd ..
fi

read "?Open folder $DOSBOXFOLDER/src (y/N)? " 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then
	open ./src
fi

fi  ## this ends build dynamic-linked block

###--------------------------------- # Build static-linked dosbox

# echo
# read "?Build static-linked dosbox in $DOSBOXFOLDER? (y/N) " 
# echo 
# if [[ $REPLY =~ ^[Yy]$ ]] ; then			# start build-static-linked block

# if [ -f "$DOSBOXFOLDER/src/dosbox.cpp" ] ; then	# checking for at least one source file
# 		echo Source folder seems to be correct.
# 	else
# 		echo
# 		echo Could not find source files in $DOSBOXFOLDER. Aborting.
# 		exit
# fi

# distclean

# cd $DOSBOXFOLDER
# # autoheader -f 	## uncomment in case of errors
# # autoconf -f
# # automake -f 
# ./autogen.sh 
# chmod +x ./configure
# ./configure -q --prefix=$BUILDFOLDER/x86_64 --disable-sdltest --disable-alsatest   || {    
# DIE=1
# error_quit "$(( $LINENO -2 )) : configure failed."
# }

# make clean >/dev/null

# echo && echo Dynamic-linked dosbox built in $DOSBOXFOLDER/src
# echo

# read "?Run static-linked dosbox in $DOSBOXFOLDER/src (y/N)? " 
# echo 
# if [[ $REPLY =~ ^[Yy]$ ]] ; then
# 	cd ./src
#     echo '[cpu]'>testdosbox.conf
#     echo 'core=dynamic'>>testdosbox.conf
#     echo '[autoexec]'>>testdosbox.conf
#     echo 'config -get cpu'>>testdosbox.conf
#     ./dosbox -conf ./testdosbox.conf
# 	cd ..
# fi

# read "?Open folder $DOSBOXFOLDER/src (y/N)? " 
# echo 
# if [[ $REPLY =~ ^[Yy]$ ]]
# then
# 	open ./src
# fi

# fi		# end build-static-linked block

###--------------------------------- # Create $APPNAME.app

echo
read "?Create macOS $APPNAME.app in $DOSBOXFOLDER/src? (y/N) " 
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then	# start build-app block

if [ -f "$DOSBOXFOLDER/src/dosbox" ] ; then
		echo
	else
		echo Cannot build app in $DOSBOXFOLDER/src. Dosbox executable not found.
		echo
		exit
fi

cd $DOSBOXFOLDER/src

if [ -f "$DOSBOXFOLDER/src/$APPNAME.app/Contents/PkgInfo" ] ; then
	read "?I must delete the existing $APPNAME.app in $DOSBOXFOLDER/src. OK? (y/N) "
		echo 
		if [[ $REPLY =~ ^[Yy]$ ]] ; then	
			rm -rf $DOSBOXFOLDER/src/$APPNAME.app/*
			rmdir $DOSBOXFOLDER/src/$APPNAME.app
		else
			echo "Existing $APPNAME.app not deleted. Exiting."
			exit
		fi
fi

read "?Copy a custom icon to use for macOS app? (y/N) "
	echo 
		if [[ $REPLY =~ ^[Yy]$ ]] ; then	
			vared -p "Enter full path of custom icon (no tilde): " -c ICONPATH
				if [[ ! -a $ICONPATH ]]; then
					echo "$ICONPATH not found."
					vared -p "Enter full path of custom icon (no tilde): " -c ICONPATH
					if [[ ! -a $ICONPATH ]]; then
						echo "$ICONPATH not found. Run me again."
						exit
					fi
				else
					cp $ICONPATH $DOSBOXFOLDER/src/platform/macosx/dosbox.icns
				fi
			
		fi
echo
echo "Creating $APPNAME.app ..."
echo 
mkdir -p $APPNAME.app/Contents/MacOS
cp dosbox $APPNAME.app/Contents/MacOS/DOSBox
echo 'APPL????' >$APPNAME.app/Contents/PkgInfo
mkdir -p $APPNAME.app/Contents/Resources
cp $DOSBOXFOLDER/src/platform/macosx/dosbox.icns $APPNAME.app/Contents/Resources/dosbox.icns		
cd $APPNAME.app/Contents

echo '<?xml version="1.0" encoding="UTF-8"?>' >> Info.plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> Info.plist
echo '<plist version="1.0">' >> Info.plist
echo '<dict>' >> Info.plist
echo '	<key>CFBundleDevelopmentRegion</key>' >> Info.plist
echo '	<string>English</string>' >> Info.plist
echo '	<key>CFBundleDisplayName</key>' >> Info.plist
echo '	<string>'$APPNAME'</string>' >> Info.plist
echo '	<key>CFBundleExecutable</key>' >> Info.plist
echo '	<string>DOSBox</string>' >> Info.plist
echo '	<key>CFBundleGetInfoString</key>' >> Info.plist
echo '	<string>SVN, Copyright 2002-2021 The DOSBox Team</string>' >> Info.plist
echo '	<key>CFBundleIconFile</key>' >> Info.plist
echo '	<string>dosbox.icns</string>' >> Info.plist
echo '	<key>CFBundleInfoDictionaryVersion</key>' >> Info.plist
echo '	<string>6.0</string>' >> Info.plist
echo '	<key>CFBundleName</key>' >> Info.plist
echo '	<string>'$APPNAME'</string>' >> Info.plist
echo '	<key>CFBundlePackageType</key>' >> Info.plist
echo '	<string>APPL</string>' >> Info.plist
echo '	<key>CFBundleShortVersionString</key>' >> Info.plist
echo '	<string>SVN</string>' >> Info.plist
echo '	<key>CFBundleVersion</key>' >> Info.plist
echo '	<string>SVN</string>' >> Info.plist
echo '	<key>NSHumanReadableCopyright</key>' >> Info.plist
echo '	<string>Copyright 2002-2021 The DOSBox Team</string>' >> Info.plist
echo '	<key>NSPrincipalClass</key>' >> Info.plist
echo '	<string>NSApplication</string>' >> Info.plist
echo '	<key>CGDisableCoalescedUpdates</key>' >> Info.plist
echo '	<true/>' >> Info.plist
echo '</dict>' >> Info.plist
echo '</plist>' >> Info.plist

cd ../..

# echo && echo
read "?Open folder $DOSBOXFOLDER/src, where you can run $APPNAME.app (y/N)? " 
	echo 
	if [[ $REPLY =~ ^[Yy]$ ]] ; then
	open .
	fi

fi

###--------------------------------- # run dylibbundler to create portable app bundle

# echo && echo
read "?Create portable $APPNAME.app in $DOSBOXFOLDER/src (y/N)? "
echo 
if [[ $REPLY =~ ^[Yy]$ ]] ; then
	cd $DOSBOXFOLDER/src
	$BUILDFOLDER/macdylibbundler-master/dylibbundler -od -b -x $APPNAME.app/Contents/MacOS/dosbox -d  $APPNAME.app/Contents/Resources/lib -p @executable_path/../Resources/lib -i /usr/lib
	echo 
	echo "Portable $APPNAME.app created."
	echo 

	read "?Open folder $DOSBOXFOLDER/src, where you can run $APPNAME.app (y/N)? " 
	echo 
	if [[ $REPLY =~ ^[Yy]$ ]] ; then
	open .
	fi

fi

###--------------------------------- # end of overall build block

echo 

fi			# ends overall build block

###--------------------------------- # Finish up

fi	# ends test not uninst block

echo
exit
