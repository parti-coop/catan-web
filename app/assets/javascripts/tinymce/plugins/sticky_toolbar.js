// PC 툴바 위치 고정
/******/ (function(modules) { // webpackBootstrap
/******/  // The module cache
/******/  var installedModules = {};
/******/
/******/  // The require function
/******/  function __webpack_require__(moduleId) {
/******/
/******/    // Check if module is in cache
/******/    if(installedModules[moduleId]) {
/******/      return installedModules[moduleId].exports;
/******/    }
/******/    // Create a new module (and put it into the cache)
/******/    var module = installedModules[moduleId] = {
/******/      i: moduleId,
/******/      l: false,
/******/      exports: {}
/******/    };
/******/
/******/    // Execute the module function
/******/    modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/    // Flag the module as loaded
/******/    module.l = true;
/******/
/******/    // Return the exports of the module
/******/    return module.exports;
/******/  }
/******/
/******/
/******/  // expose the modules object (__webpack_modules__)
/******/  __webpack_require__.m = modules;
/******/
/******/  // expose the module cache
/******/  __webpack_require__.c = installedModules;
/******/
/******/  // define getter function for harmony exports
/******/  __webpack_require__.d = function(exports, name, getter) {
/******/    if(!__webpack_require__.o(exports, name)) {
/******/      Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/    }
/******/  };
/******/
/******/  // define __esModule on exports
/******/  __webpack_require__.r = function(exports) {
/******/    if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/      Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/    }
/******/    Object.defineProperty(exports, '__esModule', { value: true });
/******/  };
/******/
/******/  // create a fake namespace object
/******/  // mode & 1: value is a module id, require it
/******/  // mode & 2: merge all properties of value into the ns
/******/  // mode & 4: return value when already ns object
/******/  // mode & 8|1: behave like require
/******/  __webpack_require__.t = function(value, mode) {
/******/    if(mode & 1) value = __webpack_require__(value);
/******/    if(mode & 8) return value;
/******/    if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/    var ns = Object.create(null);
/******/    __webpack_require__.r(ns);
/******/    Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/    if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/    return ns;
/******/  };
/******/
/******/  // getDefaultExport function for compatibility with non-harmony modules
/******/  __webpack_require__.n = function(module) {
/******/    var getter = module && module.__esModule ?
/******/      function getDefault() { return module['default']; } :
/******/      function getModuleExports() { return module; };
/******/    __webpack_require__.d(getter, 'a', getter);
/******/    return getter;
/******/  };
/******/
/******/  // Object.prototype.hasOwnProperty.call
/******/  __webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/  // __webpack_public_path__
/******/  __webpack_require__.p = "";
/******/
/******/
/******/  // Load entry module and return exports
/******/  return __webpack_require__(__webpack_require__.s = 0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// CONCATENATED MODULE: ./src/plugin.js
var plugin_plugin = function plugin(editor) {
  var offset = editor.settings.sticky_offset ? editor.settings.sticky_offset : 0;
  editor.on('init', function () {
    setTimeout(function () {
      setSticky();
    }, 0);

    var $scroll_container = $(editor.getContainer()).closest('.js-stickytoolbar-scroll-container');
    var scroll_listener;
    if($scroll_container.length <= 0) {
      scroll_listener = window;
    } else {
      scroll_listener = $scroll_container[0];
    }
    scroll_listener.addEventListener('resize', function () {
      setSticky();
    });
    scroll_listener.addEventListener('scroll', function () {
      setSticky();
    });
  });

  function setSticky() {
    var container = editor.getContainer();
    var toolbars = container.querySelectorAll('.tox-menubar, .tox-toolbar, .tox-toolbar-overlord');
    var toolbarHeights = 0;
    toolbars.forEach(function (toolbar) {
      toolbarHeights += toolbar.offsetHeight;
    });

    if (!editor.inline && container && container.offsetParent) {
      var statusbar = '';

      if (editor.settings.statusbar !== false) {
        statusbar = container.querySelector('.tox-statusbar');
      }

      if (isSticky()) {
        container.style.paddingTop = "".concat(toolbarHeights, "px");

        if (isAtBottom()) {
          var nextToolbarHeight = 0;
          var toolbarsArray = [].slice.call(toolbars).reverse();
          toolbarsArray.forEach(function (toolbar) {
            toolbar.style.top = null;
            toolbar.style.width = '100%';
            toolbar.style.position = 'absolute';
            toolbar.style.bottom = statusbar ? "".concat(statusbar.offsetHeight + nextToolbarHeight, "px") : 0;
            toolbar.style.zIndex = 1;
            nextToolbarHeight = toolbar.offsetHeight;
          });
        } else {
          var prevToolbarHeight = 0;
          toolbars.forEach(function (toolbar) {
            toolbar.style.bottom = null;
            toolbar.style.top = "".concat(dynamicOffset(container) + offset + prevToolbarHeight, "px");
            toolbar.style.position = 'fixed';
            toolbar.style.width = "".concat(container.clientWidth, "px");
            toolbar.style.zIndex = 1;
            prevToolbarHeight = toolbar.offsetHeight;
          });
        }
      } else {
        container.style.paddingTop = 0;
        toolbars.forEach(function (toolbar) {
          toolbar.style = null;
        });
      }
    }
  }

  function isSticky() {
    var editorPosition = editor.getContainer().getBoundingClientRect().top;

    if (editorPosition < (dynamicOffset(editor.getContainer()) + offset)) {
      return true;
    }

    return false;
  }

  function isAtBottom() {
    var container = editor.getContainer();
    var editorPosition = container.getBoundingClientRect().top,
        statusbar = container.querySelector('.tox-statusbar'),
        toolbars = container.querySelectorAll('.tox-menubar, .tox-toolbar, .tox-toolbar-overlord');
    var statusbarHeight = statusbar ? statusbar.offsetHeight : 0;
    var toolbarHeights = 0;
    toolbars.forEach(function (toolbar) {
      toolbarHeights += toolbar.offsetHeight;
    });
    var stickyHeight = -(container.offsetHeight - toolbarHeights - statusbarHeight);

    if (editorPosition < stickyHeight + dynamicOffset(container) + offset) {
      return true;
    }

    return false;
  }

  function dynamicOffset(container) {
    var $scroll_container = $(container).closest('.js-stickytoolbar-scroll-container');
    if($scroll_container.length <= 0) {
      var $offsets = $('.js-stickytoolbar-offset').filter(function () {
        return $(this).css('position') == 'fixed';
      });
      var absoluteTop = 0;
      $offsets.each(function() {
        absoluteTop += parseFloat($(this).outerHeight());
      });
    } else {
      absoluteTop = $scroll_container.position().top;
    }

    return absoluteTop;
  }
};

/* harmony default export */ var src_plugin = (plugin_plugin);
// CONCATENATED MODULE: ./src/index.js

tinymce.PluginManager.add('stickytoolbar', src_plugin);

/***/ })
/******/ ]);
