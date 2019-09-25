# JDFramework
将真机模拟器合并的脚本


Framewrok真机模拟器合并的流程、原因就不说了。

为什么要写这篇文章了，因为自己也吃过苦，一开始也是各种网上收，

可是好多脚本要嘛格式一塌糊涂，要嘛脚本堆在一起，要嘛编译不了（很多都是worksapce用的是project的脚本，project用的是workspace的脚本），反正一开始新手问题超级多，并且修改路径也麻烦！所以写了这么个脚本(其实核心都是一样的)。

该脚本有以下优点

1、方法都封装好，便于新手一个一个方法去看，不至于头大

2、用户可以很简单的自定义输出目录

3、代码更精简、更简单，应该算是傻瓜式的啦

4、自定帮你清理缓存，打出的framework不会出现 咦，为啥代码改过还是不变！

5、最重要，支持project和workspace的编译，只需要把相应的代码打开注释就行  很多网上的教程都没有哦

脚本在下面，拷贝过去直接可以用

```c

STYLE="0"
#STYLE="1"

#用来存放合并的framework
if [ "${STYLE}" == "0" ];then
OUTPUTFOLDER=${BUILD_DIR}
else
OUTPUTFOLDER=build
fi

#合并后的文件夹名称后缀
OUTPUTFOLDER_SUFFIX="universal"

#用户自定义的目录，可以帮你拷贝到你想要的目录
LIB_OUTPUTFOLDER=../Libs


WORKSPACE_NAME=${PROJECT_NAME}.xcworkspace
TARGET_NAME="JDFramework"

YO_SCHEME=${PROJECT_NAME}


function build_static_library {
    #编译workspace
    if [ "${STYLE}" == "0" ];then
    xcodebuild -workspace ${WORKSPACE_NAME} \
    -scheme ${YO_SCHEME} \
    -sdk ${1} \
    -configuration ${2}
    else
    #编译工程 打开这个注释你就可以编译project 但是注意要把下面的命令隐藏掉
    xcodebuild  -target "${TARGET_NAME}" -sdk ${1} -configuration ${2} clean build
    fi
    
}

function make_fat_library {
    xcrun lipo -create \
    "${OUTPUTFOLDER}/$1-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
    "${OUTPUTFOLDER}/$1-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
    -output \
    "${OUTPUTFOLDER}/$1-${OUTPUTFOLDER_SUFFIX}/${PROJECT_NAME}.framework/${PROJECT_NAME}"
}

#重新创建目录
function rmkdir_library {
    rm -rf "${OUTPUTFOLDER}/${1}-${OUTPUTFOLDER_SUFFIX}"
    mkdir -p "${OUTPUTFOLDER}/${1}-${OUTPUTFOLDER_SUFFIX}"
}

#拷贝一份头文件
function cp_library_header {
    cp -R "${OUTPUTFOLDER}/${1}-iphonesimulator/${PROJECT_NAME}.framework" "${OUTPUTFOLDER}/${1}-${OUTPUTFOLDER_SUFFIX}/${PROJECT_NAME}.framework"
}

#根据环境编译
function build_platform {
    #先清理老的
    rm -rf "${OUTPUTFOLDER}"
    rm -rf \
    "${LIB_OUTPUTFOLDER}/${PROJECT_NAME}.framework"
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
    ditto ${OUTPUTFOLDER}/$1-${OUTPUTFOLDER_SUFFIX}/${PROJECT_NAME}.framework \
    "${LIB_OUTPUTFOLDER}/${PROJECT_NAME}.framework"
}

build_platform ${CONFIGURATION}

#open "${OUTPUTFOLDER}"


```
