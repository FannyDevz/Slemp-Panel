#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`

rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sourcePath=${serverPath}/source/php

LIBNAME=apc
LIBV=3.1.9
sysName=`uname`
actionType=$1
version=$2

NON_ZTS_FILENAME=`ls $serverPath/php/${version}/lib/php/extensions | grep no-debug-non-zts`
extFile=$serverPath/php/${version}/lib/php/extensions/${NON_ZTS_FILENAME}/${LIBNAME}.so

if [ "$sysName" == "Darwin" ];then
	BAK='_bak'
else
	BAK=''
fi

Install_lib()
{
	isInstall=`cat $serverPath/php/$version/etc/php.ini|grep "${LIBNAME}.so"`
	if [ "${isInstall}" != "" ];then
		echo "php-$version ${LIBNAME} has been installed, please choose another version!"
		return
	fi
	
	if [ ! -f "$extFile" ];then

		_LIBNAME=$(echo $LIBNAME | tr '[a-z]' '[A-Z]')
		php_lib=$sourcePath/php_lib
		mkdir -p $php_lib
		if [ ! -d $php_lib/${_LIBNAME}-${LIBV} ];then
			wget -O $php_lib/${LIBNAME}-${LIBV}.tgz http://pecl.php.net/get/${_LIBNAME}-${LIBV}.tgz
			cd $php_lib
			tar xvf ${LIBNAME}-${LIBV}.tgz
		fi
		cd $php_lib/${_LIBNAME}-${LIBV}

		$serverPath/php/$version/bin/phpize
		./configure --with-php-config=$serverPath/php/$version/bin/php-config && \
		make && make install && make clean

	fi
	
	if [ ! -f "$extFile" ];then
		echo "ERROR!"
		return
	fi

	echo "" >> $serverPath/php/$version/etc/php.ini
	echo "[${LIBNAME}]" >> $serverPath/php/$version/etc/php.ini
	echo "extension=${LIBNAME}.so" >> $serverPath/php/$version/etc/php.ini

	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==========================================================='
	echo 'successful!'
}


Uninstall_lib()
{
	if [ ! -f "$serverPath/php/$version/bin/php-config" ];then
		echo "php-$version is not installed, please choose another version!"
		return
	fi
	
	echo $extFile
	if [ ! -f "$extFile" ];then
		echo "php-$version ${LIBNAME} is not installed, please choose another version!"
		echo "php-$version not install ${LIBNAME}, Plese select other version!"
		return
	fi
	
	sed -i $BAK "/${LIBNAME}.so/d" $serverPath/php/$version/etc/php.ini
	sed -i $BAK "/${LIBNAME}/d" $serverPath/php/$version/etc/php.ini
		
	rm -f $extFile
	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==============================================='
	echo 'successful!'
}


if [ "$actionType" == 'install' ];then
	Install_lib
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_lib
fi