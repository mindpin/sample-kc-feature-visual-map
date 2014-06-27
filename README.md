sample-kc-feature-visual-map
============================

KnowledgeCamp 产品 SAMPLE-1 用于展示可视化知识网络图的绘制

### compile

```
scss --watch .
coffee --output js/graph/dist -wcm js/graph/src
ruby watch_haml.rb .
```

------------------

### run sample

```
ruby -run -e httpd . -p 4000
```

### test

```
test.html
```

### 参考
sea.js 和 assets pipeline 并不容易整合<br/>
这篇文章或许可以参考：http://chaoskeh.com/blog/how-to-integrates-seajs-with-rails.html