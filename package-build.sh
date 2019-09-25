#!/bin/sh

#workspace=0
workspace=0

BASEDIR=$PWD
#用来存放合并的framework
OUTPUTFOLDER=$BASEDIR/build

#合并后的文件夹名称后缀
OUTPUTFOLDER_SUFFIX="universal"

#用户自定义的目录，可以帮你拷贝到你想要的目录
LIB_OUTPUTFOLDER=$BASEDIR/Libs

PROJECT_NAME=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
WORKSPACE_NAME=${PROJECT_NAME}.xcworkspace
YO_SCHEME=${PROJECT_NAME}

TARGET_NAME=${PROJECT_NAME}

#-workspace 是否是workspace
#选项和参数
while [ -n "$1" ]
do
    case "$1" in
        -workspace) workspace=1 ;;
        -scheme) YO_SCHEME="$2"
            shift ;;
        -out) LIB_OUTPUTFOLDER="$2"
            shift ;;
        --) shift
        break ;;
        *) echo "$1 is not an option" ;;
    esac
    shift
done



function clean_project {
    echo "\033[33m 清理build目录... \033[0m"
    rm -rf ${LIB_OUTPUTFOLDER}/${YO_SCHEME}.framework
    rm -rf ${OUTPUTFOLDER}
    xcodebuild clean
}

function build_static_library {
    sdkType=$1
    configuration=$2
    other_build=""
    #编译workspace
    if [ ${workspace} == 1 ];then
        if [ $sdkType ==  iphonesimulator ]; then
            other_build="ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO"
        fi
        echo "\033[33m xcodebuild ${other_build} -workspace ${WORKSPACE_NAME} -scheme ${YO_SCHEME} -sdk ${sdkType} -configuration ${configuration} \033[0m"
        xcodebuild ${other_build} -workspace ${WORKSPACE_NAME} -scheme ${YO_SCHEME} -sdk ${sdkType} -configuration ${configuration} CONFIGURATION_BUILD_DIR=${OUTPUTFOLDER}/${configuration}-${sdkType}
    else
        #编译工程 打开这个注释你就可以编译project 但是注意要把下面的命令隐藏掉
        if [ $1 ==  iphonesimulator ]; then
            other_build="ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO"
        fi
        echo "\033[33m xcodebuild ${other_build} -target ${TARGET_NAME} -sdk ${sdkType} -configuration ${configuration} build \033[0m"
        xcodebuild ${other_build} -target "${TARGET_NAME}" -sdk ${sdkType} -configuration ${configuration} build CONFIGURATION_BUILD_DIR=${OUTPUTFOLDER}/${configuration}-${sdkType}
    fi
}


#重新创建目录
function rmkdir_library {
    configuration=$1
    rm -rf ${OUTPUTFOLDER}/${configuration}-${OUTPUTFOLDER_SUFFIX}
    mkdir -p ${OUTPUTFOLDER}/${configuration}-${OUTPUTFOLDER_SUFFIX}
}

#拷贝一份头文件
function cp_library_header {
    configuration=$1
    cp -R ${OUTPUTFOLDER}/${configuration}-iphonesimulator/${YO_SCHEME}.framework ${OUTPUTFOLDER}/${configuration}-${OUTPUTFOLDER_SUFFIX}/${YO_SCHEME}.framework
}

function make_fat_library {
    configuration=$1
    echo "\033[33m xcrun lipo -create ${OUTPUTFOLDER}/${configuration}-iphonesimulator/${YO_SCHEME}.framework/${YO_SCHEME} ${OUTPUTFOLDER}/${configuration}-iphoneos/${YO_SCHEME}.framework/${YO_SCHEME} -output ${OUTPUTFOLDER}/${configuration}-${OUTPUTFOLDER_SUFFIX}/${YO_SCHEME}.framework/${YO_SCHEME} \033[0m"

    xcrun lipo -create ${OUTPUTFOLDER}/${configuration}-iphonesimulator/${YO_SCHEME}.framework/${YO_SCHEME} \
    ${OUTPUTFOLDER}/${configuration}-iphoneos/${YO_SCHEME}.framework/${YO_SCHEME} \
    -output ${OUTPUTFOLDER}/${configuration}-${OUTPUTFOLDER_SUFFIX}/${YO_SCHEME}.framework/${YO_SCHEME}

    if [ $? -eq 0 ]; then
        echo "\033[33m 👏👏👏build success \033[0m"
    else
        echo "\033[33m 😭😭😭build faild \033[0m"
    fi
}


#根据环境编译
function build_platform {
    #先清理老的
    clean_project
    #编译模拟器
    build_static_library iphonesimulator ${1}
    #编译真机
    build_static_library iphoneos ${1}
    
    #重新创建目录
    rmkdir_library ${1}
    # 因为framework的合并,lipo只是合并了最后的 二进制可执行文件,所以其它的需要我们自己复制过来
    cp_library_header ${1}
    
    # 合并模拟器和真机的架构
    make_fat_library ${1}
    
    # 拷贝framewrok到用户的目录
    echo "\033[33m  ditto ${OUTPUTFOLDER}/$1-${OUTPUTFOLDER_SUFFIX}/${YO_SCHEME}.framework ${LIB_OUTPUTFOLDER}/${YO_SCHEME}.framework \033[0m"
    ditto ${OUTPUTFOLDER}/$1-${OUTPUTFOLDER_SUFFIX}/${YO_SCHEME}.framework ${LIB_OUTPUTFOLDER}/${YO_SCHEME}.framework
}

build_platform "Release"

