'use strict';
/**
 * Helper shows vanilla reloadable helper test service
 * why: When you want to reload services with your apps
 */
( function() {

  //console.error('reloding quickUI')

  var isNode = true

  if (typeof exports === 'undefined' || exports.isNode == false) {
    isNode = false
  }

  function QuickJSONConvertor(sh) {
    var self = this;
    var p = this;

    p.init = function init() {
      self.settings = {};
      self.data = {};
      self.data.json = []
    }

    p.new = function create() {
      var s = new QuickJSONConvertor();
      console.log('inside create', ',,,,,,7,,,,,,')
      // debugger;
      s.init();
      return s;
    }

    function defineSlideMethods2() {
      //why: characters, questions, deocration
      p.slide = function slide(name) {
        self.currentSlide = {}
        self.addToSlideIf(name, 'name')
        self.data.json.push(self.currentSlide)
        //debugger
        return self;
      }

      p.addToSlideIf = function addTO(val, prop, isArray) {
        if ( prop == null ) throw new Error('prop not defined');
        if ( val == null ) return;

        self.currentSlide[prop] = val;
        if ( isArray === true ) {
          var curVal =  self.currentSlide[prop]
          if ( curVal == null ) curVal = [];
          curVal.push(val)
        }

      }
    }
    defineSlideMethods2();

    function defineCharacterMethods() {
      //why: assets, audio, animations
      p.char = function addCharacter(name) {
        var char  = {};
        self.currentCharacter = char
        self.utils.addToObjectIf(self.currentCharacter, name, 'name')
        self.utils.addToObjectIf(self.currentSlide, char, 'characters', true)
        //debugger
        return self;
      }

      p.addToSlideIf = function addTO(val, prop, isArray) {
        if ( prop == null ) throw new Error('prop not defined');
        if ( val == null ) return;

        self.currentSlide[prop] = val;
        if ( isArray === true ) {
          var curVal =  self.currentSlide[prop]
          if ( curVal == null ) curVal = [];
          curVal.push(val)
        }

      }
    }
    defineCharacterMethods();


    function defineUtils() {
      var utils = {}
      self.utils = utils;

      utils.addToObjectIf = function addTO(obj, val, prop, isArray) {
        if ( prop == null ) throw new Error('prop not defined');
        if ( obj == null ) throw new Error('obj not defined, '+ arguments);
        if ( val == null ) return;

        if ( isArray === true ) {
          var curVal = obj[prop]
          if ( curVal == null ) curVal = [];
          curVal.push(val)
          obj[prop] = curVal;
          return;
        }

        obj[prop] = val;


      }
    }
    defineUtils();
    p.json = function json() {
      var d = sh;

      /// debugger;
      //self.currentSlide = []
      return  self.data.json ;
      // return sh.toJSONString( self.data.json);
    }

    p.getAttributes = function (el) {

      var nodes=[], values=[];
      var attrs = {};
      for (var att, i = 0, atts = el.attributes, n = atts.length; i < n; i++){
        att = atts[i];
        nodes.push(att.nodeName);
        values.push(att.nodeValue);
        attrs[att.nodeName]=att.nodeValue
      }
      attrs.$names = nodes;
      return attrs
    };

    p.getCSS = function (el) {
      var nodes=[], values=[];
      var css = {};
      for (var att, i = 0, atts = el.attributes, n = atts.length; i < n; i++){
        att = atts[i];
        nodes.push(att.nodeName);
        values.push(att.nodeValue);
        css[att.nodeName]=att.nodeValue
      }
      css.$names = nodes;
      return css
    };


    p.process = function process(elStart, dictTypes, dictAttrs) {
      console.info('process quick inf', dictAttrs)
      //console.error('loading version', QuickUIConvertor.version, window.QuickUIConvertor.version)
      var children = elStart.find('*');
      var ifx = function ifXHasPropCallFxWithVal(x, prop, fx) {
        if ( x[prop] != null ) {
          fx(x[prop])
        }
      }

      function transformElement( el, def) {
        var q = $(el);
        //do before changed by changeTo
        ifx(def, 'addHTML', function(addHTML){
          q.append($(addHTML))}
        );
        ifx(def, 'fx', function(fx){fx(el, def)} );
        ifx(def, 'addClass', function(addClass){q.addClass(addClass)} );
        ifx(def, 'addCSS', function(addCSS){q.css(addCSS)} );

        if ( def.changeTo != null ) {
          q.replaceTagName( def.changeTo );
        };
        if ( def.replaceWith != null ) {
          console.log(q, q.html())
          // debugger
          q.replaceWith( def.replaceWith ); //TODO: Keep attributes?
        };
      }

      //debugger
      //todo run jquery to find elements to apply transforms
      $.each(children, function (i,inputElement) {
        //console.log(i);
        var q = $(inputElement);
        var element = null;
        var el = element = q[0];
        var type = element.tagName.toLowerCase();
        var attrs = self.getAttributes(element);////.attr();

        var it = {};

        var typeDef = dictTypes[type]
        if ( typeDef != null ) {
          transformElement(el, typeDef);
        }

        var ifxEq = function ifXHasPropCallFxWithVal(x, prop, val) {
          if ( x[prop] == val ) {
            return true;
          }
          return false;
        }

        $.each(attrs, function (attrName, val) {
          //search for matching attr change definition in dictionary
          //apply dictAttrs blocks
          var attrDef =  dictAttrs[attrName]
          if ( attrDef == null ) {
            return;
          }
          if ( attrDef.keep !== true ) {
            q.attr(attrName, null);
          }
          if ( attrDef.alert )
            console.warn('alert triggered', q, attrName, val);
          if ( attrDef.addClassToChildren ) {
            $.each(q.children(), function addStyleChild(k,v) {
              $(v).addClass(attrDef.addClassToChildren)
            });
          }

          if ( attrDef.modifyChildrenFx ) { //use method to modify children
            $.each(q.children(), function addStyleChild(k,v) {
              var childAttrs = self.getAttributes(v);////.attr();
              var css = self.getCSS(v)
              attrDef.modifyChildrenFx($(v),k,childAttrs, css, attrs)
              //$(v).addClass('show-child-containers')
            });
          }

          if ( attrDef.debugChildren ) {
            it.debugChildren = true;
          }


          var skipAttr = false;
          //TODO: what was purpose of ifVal?
          /*if ( ifxEq(attrDef, 'ifVal', true ) ) {
           if ( val == 'true' || val == true ) {

           } else {
           return;
           }
           };*/
          if ( skipAttr == true )
            return;
          transformElement(el, attrDef);

        })

        if ( it.debugChildren || attrs['debugChildren']) { //can debug all of type, or just one from dom
          $.each(q.children(), function addStyleChild(k,v) {
            $(v).addClass('show-child-containers')
          });
        }

      });
    }

  }



  if ( typeof angular != 'undefined') {
    //debugger
    var wrapperRelodableService = window.reloadableHelper.makeServiceReloadable('QuickJSONService', QuickJSONConvertor)
    //  debugger;
    angular.module('com.sync.quick').factory('quickJSON', wrapperRelodableService);
  }
}());
