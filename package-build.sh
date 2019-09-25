#!/bin/sh

#workspace=0
workspace=0

#-build build
#选项和参数
while [ -n "$1" ]
do
    case "$1" in
        -workspace) workspace=1 ;;
        --) shift
    break ;;
        *) echo "$1 is not an option" ;;
    esac
    shift
done


#用来存放合并的framework
OUTPUTFOLDER=build

#合并后的文件夹名称后缀
OUTPUTFOLDER_SUFFIX="universal"

#用户自定义的目录，可以帮你拷贝到你想要的目录
LIB_OUTPUTFOLDER=Libs

PROJECT_NAME=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
WORKSPACE_NAME=${PROJECT_NAME}.xcworkspace
TARGET_NAME=${PROJECT_NAME}

YO_SCHEME=${PROJECT_NAME}


function clean_project {
    echo "清理build目录..."
    rm -rf ${LIB_OUTPUTFOLDER}/${PROJECT_NAME}.framework
    xcodebuild clean
}

function build_static_library {
    #编译workspace
    if [ ${workspace} == 1 ];then
        if [ $1 ==  iphonesimulator ]; then
            echo "xcodebuild ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO -workspace ${WORKSPACE_NAME} -scheme ${YO_SCHEME} -sdk ${1} -configuration ${2}"
            xcodebuild ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO -workspace ${WORKSPACE_NAME} -scheme ${YO_SCHEME} -sdk ${1} -configuration ${2}
        else
            echo "xcodebuild -workspace ${WORKSPACE_NAME} -scheme ${YO_SCHEME} -sdk ${1} -configuration ${2}"
            xcodebuild -workspace ${WORKSPACE_NAME} -scheme ${YO_SCHEME} -sdk ${1} -configuration ${2}
        fi


    else

        #编译工程 打开这个注释你就可以编译project 但是注意要把下面的命令隐藏掉
        if [ $1 ==  iphonesimulator ]; then
            echo "xcodebuild ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO  -target ${TARGET_NAME} -sdk ${1} -configuration ${2} clean build"
            xcodebuild ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO  -target "${TARGET_NAME}" -sdk ${1} -configuration ${2} build
        else
            echo "xcodebuild   -target ${TARGET_NAME} -sdk ${1} -configuration ${2} clean build"
            xcodebuild  -target "${TARGET_NAME}" -sdk ${1} -configuration ${2} build
        fi

    fi
    
}

function make_fat_library {
    xcrun lipo -create ${OUTPUTFOLDER}/$1-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME} \
    ${OUTPUTFOLDER}/$1-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME} \
    -output ${OUTPUTFOLDER}/$1-${OUTPUTFOLDER_SUFFIX}/${PROJECT_NAME}.framework/${PROJECT_NAME}
}

#重新创建目录
function rmkdir_library {
    rm -rf ${OUTPUTFOLDER}/${1}-${OUTPUTFOLDER_SUFFIX}
    mkdir -p ${OUTPUTFOLDER}/${1}-${OUTPUTFOLDER_SUFFIX}
}

#拷贝一份头文件
function cp_library_header {
    cp -R ${OUTPUTFOLDER}/${1}-iphonesimulator/${PROJECT_NAME}.framework ${OUTPUTFOLDER}/${1}-${OUTPUTFOLDER_SUFFIX}/${PROJECT_NAME}.framework
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
    ditto ${OUTPUTFOLDER}/$1-${OUTPUTFOLDER_SUFFIX}/${PROJECT_NAME}.framework "${LIB_OUTPUTFOLDER}/${PROJECT_NAME}.framework"
}

build_platform "Release"

#open "${OUTPUTFOLDER}"
