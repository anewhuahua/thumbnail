# BILIBILI THUMBNAIL

      
Thumbnail is a package which provide image resize functionality in nginx request lifecycle.  
Thumbnail relies on lua nginx module which provides lua scripting interface in nginx.  
Thumbnail relies on opencv library which provide image resize functionality.  

Thumbnail is consist of three parts:  
nginx configuration which under thumbnail/nginx/nginx.conf  
lua script which is invoked by lua nginx module while receiving a image uri request.  
opencv wrapper(c++ file) to call opencv library.  
  
## Environment
Debian version 8.2  
Lua 5.1  
Nginx 1.8.1  
Tengine/2.1.2 (nginx/1.6.2)    
   
## Build
  **Install Dependencies:**   
    $ apt-get install -y libpcre3 libpcre3-dev libltdl-dev libssl-dev libjpeg62-turbo-dev libpng12-0 libpng12-dev libcurl4-openssl-dev libmcrypt-dev autoconf libxslt1-dev libgd2-noxpm-dev libgeoip-dev libperl-dev   
    $ apt-get install -y lua5.1 liblua5.1-0 liblua5.1-0-dev   
    $ apt-get install -y libopencv-dev    
     
  **Build opencv Wrapper:**    
    $ git clone    
    $ cd lua-opencv   
    $ make clean  
    $ make linux   

  **Build Nginx:**   
           
    ***For Nginx 1.8.1***    
    $ ./configure --prefix=/usr/local/nginx --with-debug \    
      --with-http_addition_module --with-http_dav_module \   
      --with-http_gzip_static_module --with-http_perl_module \  
      --with-http_realip_module --with-http_secure_link_module \   
      --with-http_ssl_module --add-module=/data/thumbnail/nginx/module/ngx_devel_kit \  
      --add-module=/data/thumbnail/nginx/module/lua-nginx-module  
    $ make  
    $ make install   
         
    ***For Tengine/2.1.2 (nginx/1.6.2)***      
    $ ./configure --prefix=/usr/local/nginx --with-debug \    
      --with-http_addition_module --with-http_dav_module \   
      --with-http_gzip_static_module --with-http_perl_module \  
      --with-http_realip_module --with-http_secure_link_module \   
      --with-http_ssl_module --add-module=/data/thumbnail/nginx/module/ngx_devel_kit    
    $ make    
    $ make install     
      
## Run
  **First:**    
  Configure /data/thumbnail/nginx/nginx.conf    
  **Then:**     
  /usr/local/nginx/sbin/nginx -c /data/thumbnail/nginx/nginx.conf    

## Benchmark
  8 CPU 2.4G, 8G RAM, Debian 8.2    
  2406.1 fetches/sec, 9.71727e+06 bytes/sec       

## Help
  curl http://XXXX:XX/lua-version   
  
## License
Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0