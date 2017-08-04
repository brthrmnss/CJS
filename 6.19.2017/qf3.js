//'use strict';

(function(){

  var reload_name = 'quickform3';
  var urlPath= 'g/js/quick/';
  var urlPath= 'lib/reloadable/comps/';

  var quickForm2 = function quickForm2_($templateRequest, $compile,
                                        $interpolate, transcludeHelper) {

    var utilsParent = transcludeHelper.new();

    function link(scope, element, attrs, ctrl, transclude){
      var urlTemplate = '';
      urlTemplate = urlPath + reload_name + '.dir.html'
      $templateRequest(urlTemplate ).then(
          function onCreateDomElements(html){

            element.on('$destroy', function(){
              //alert('qf destroyed');
            })
            scope.id = Math.random();
            //alert('created ' +  scope.id);

            //var utilsParentDict = utils.dictTemplates;
            var utils = transcludeHelper.new();
            utils.dictTemplates = utilsParent.dictTemplates; //copy over dictionary of templates
            utils.$compile = $compile;

            utilsParent.destroyDuplicateScopes(element,scope);
            utils.loadTemplate(html, element, attrs);

            //console.error('qf', 'pre-', scope.vm)
            scope.render(utils);
            

            scope.$watch('vm.formObject', function (v, oldVal) {
              if (scope.vm.formObject != null) {
                console.log('scope.vm.formObject... changed: ',
                    scope.vm.formObject, v);
              }
              console.log('quick-form scope.vm.formObject... changed: ',
                  scope.vm, v,oldVal);
            });
            scope.$watch('vm.dataObject', function (v, oldVal) {
              if (scope.vm.dataObject != null) {
                console.log('quickform',
                    'scope.vm.dataObject... changed: ',
                    scope.vm.dataObject, v);
                // asdf.g
                scope.dataObject = v;
              }
              console.log('quickform',
                  'scope.vm.dataObject... changed: ')
            });
            scope.$watch('vm.dataObject', function (v, oldVal) {
              if (scope.vm.dataObject != null) {
                console.log('quickform',
                    'scope.vm.dataObject...', 'inner', 'changed: ',
                    scope.vm.dataObject, v);
                if ( scope.vm.config != null ) {
                  if ( scope.vm.config.fxChange != null ) {
                    scope.vm.config.fxChange(v);
                  }
                }
                // scope.dataObject = v;
              }

            }, true);


            scope.$watch('dataObject', function (v, oldVal) {
              if (scope.dataObject != null) {
                /* console.log('quickform',
                 '--dataObject...', 'inner', 'changed: ',
                 scope.dataObject, v);*/
                scope.userChangedForm( );
              }
            }, true);
            //keep in mind 'formData' is an alias for 'dataObject'
            scope.$watch('vm.formData', function (v, oldVal) {
              if (scope.vm.formData != null) {
                console.log('quickform',
                    'scope.vm.formData... changed: ',
                    scope.vm.formData, v);
                scope.formData = v;
                scope.dataObject = v;


                scope.setDefaults();
              }
              /*console.log('quickform',
               'scope.vm.formData... changed: ')*/
            });

            /* scope.$watch('vm.dataObject', function (v, oldVal) {
             if (scope.vm.dataObject != null) {
             console.log('quickform',
             'scope.vm.dataObject... changed: ',
             scope.vm.dataObject, v);
             scope.dataObject = v;
             }
             //console.log('quickform',
             //  'scope.vm.dataObject... changed: ');
             });*/

            scope.$watch('vm.refresh',
                function (v, oldVal) {
                  console.log('quickform.refresh',
                      scope.vm.dataObject,
                      scope.vm, scope,
                      'scope.vm.dataObject... changed: ')

                  if ( oldVal == null ) {
                    return;
                  }
                  if ( scope.dataObject != scope.vm.dataObject ) {
                    console.error('scope diff',
                        scope.vm.dataObject,
                        scope.dataObject)
                    // scope.dataObject = scope.vm.dataObject;
                  }

                  if ( scope.vm.formObject &&
                      scope.vm.formObject.reload == true ) {
                    console.log('quickform', 'refreshing', scope.vm.config.name)
                    delete scope.vm.formObject['reload'];

                    scope.render(null, element);
                    //scope.element.html('ldddlllll')
                    ///element.html('......dd')
                  }
                });

            /*if ( scope.vm.dataObject == null ) {
             scope.vm.dataObject = {};
             }*/


            scope.$watch('vm.config',
                function (v, oldVal) {
                  console.log('quickform.vm.config',
                      scope.vm.dataObject,
                      scope.vm, scope,
                      'scope.vm.dataObject... changed: ')

                  if ( v == null ) {
                    return; //no config
                  }
                  var updateNeeded = false
                  if (  scope.dataObject != v.dataObject && v.dataObject != null  ) {
                    console.error('scope reset config',
                        v.dataObject,
                        scope.dataObject)
                    // scope.dataObject = scope.vm.dataObject;
                    scope.vm.dataObject = v.dataObject;
                    scope.vm.formObject = v.dataObject;
                    updateNeeded = true
                  }

                  if (  scope.formObject != v.formObject && v.formObject != null  ) {
                    console.error('scope reset config formObject',
                        v.formObject,
                        scope.formObject)
                    // scope.dataObject = scope.vm.dataObject;
                    scope.vm.formObject = v.formObject;
                    updateNeeded = true
                  }
                  if ( updateNeeded == true ) {
                    scope.render();
                  }

                });
          }



      )

      controllerReference.$id = Math.random();
      console.log('top', controllerReference.$id, controllerReference.title, controllerReference.items, controllerReference.items2 );
    };

    var controllerReference = null;
    var compile = function (tElem, attrs) {
      utilsParent.storeTemplate(tElem, attrs);
      function defineDirectiveDefaults() {
        if ( attrs.selectedIndex === null  ) {
          attrs['selectedIndex'] = "-1";
        };
        if ( attrs.formObject == null  ) {
          console.log('...?')
          attrs['formObject'] = "{}";
          attrs['form-object'] = "{}";
        };
        if ( attrs.dataObject == null  ) {
          console.log('...?')
          attrs['dataObject'] = "{}";
          attrs['data-object'] = "{}";
        };
        //utils.defaultAttr('dataObject', "{}", attrs);
      }
      defineDirectiveDefaults();
      return {
        pre: function(scope, element, attrs, controller){
          controllerReference = controller;
          return;
        },
        post: link
      };
    }
    var ddo = {
      scope: {
        title: '@',
        config:'=',
        refresh: '=',
        positions:'=',
        idx:'='
      },
      controller: reload_name+'Ctrl',
      controllerAs: 'vm',
      bindToController:true,
      compile: compile,
    };
    return ddo;
  };

  var quickForm2Controller2 = function
      quickForm2Controller2_ ($scope,
                              transcludeHelper,
                              sh,
                              quickFormHelper,
                              //dialogService,
                              //pubSub,
                              quickUI,
                              appService) {
    $scope.$on('$destroy', function() {
      //alert("In destroy of:" + $scope);
    });

    var config = $scope.vm.config;
    if ( config == null ) { config = {} };

    this.$scope = $scope;

    $scope.count = 1;
    $scope.increment  =function increment() {
      $scope.count++;
    }
    $scope.move  =function moveElement() {
      transcludeHelper.move('#testComp', '#testComp2');
      $scope.count++;
    }

    $scope.saveFormData = function saveFormData(fxSave2) {

      if ( $scope.errors.length > 0 ) {
        console.error('error on form');
        alert('errors')
        return;
      }

      //remove transient properties ....

      if ( $scope.vm.fxSave != null ){
        //$scope.vm.fxSave()($scope.dataObject);
        $scope.vm.fxSave()($scope.dataObject);
        //console.log('...')

      }
      var config = $scope.vm.config;
      if ( config == null ) { config = {} };
      if ( config.fxSave != null ) {
        config.fxSave($scope.dataObject);
      };

      sh.callIfDefined(fxSave2)
    }


    $scope.cancelFormData = function cancelFormData() {
      sh.callIfDefined(config.fxCancel, $scope.dataObject );
      sh.callIfDefined(config.fxCancel2, $scope.dataObject );
    }


    $scope.validateFormData = function validateFormData() {

    }

    //$scope.vm.randomBinding = '444'
    $scope.getFormObjects = function getFormObjects(  ) {
      var scope = $scope;
      var defaultFormObject = {}
      defaultFormObject.firstName = {};
      defaultFormObject.lastName = {};
      defaultFormObject.product = {type:'select',
        options:[
          {name:'Forex', value:'forex'},
          {name:'Forex2', value:'forex2'},
        ]}
      defaultFormObject.product2 = {type:'radio',
        options:[
          {name:'Forex', value:'forex'},
          {name:'Forex2', value:'forex2'},
        ]}

      var defaultDataObject = {}
      defaultDataObject.firstName = 'Jack2';
      defaultDataObject.lastName = 'Smith';

      var  formObject
      var dataObject

      //get formObject from scope
      /*     if (scope.vm.formObject != null) {
       formObject = scope.vm.formObject;
       }
       if (scope.vm.dataObject != null) {
       dataObject = scope.vm.dataObject;
       }
       if ( scope.vm.formData != null ) {
       dataObject = scope.vm.formData;
       }*/

      if ( scope.vm.config ) {
        formObject = scope.vm.config.formObject
        dataObject = scope.vm.config.dataObject
      }
      if ( formObject == null ) {
        formObject = defaultFormObject;
        console.error('formObject was not defined')
      }
      if ( dataObject == null ) {
        dataObject = defaultDataObject;
        console.error('dataObject was not defined')
      }

      var ret = {}
      ret.formObject = formObject;
      ret.dataObject = dataObject;
      return ret;
    }

    $scope.render = function render( utils ) {
      if ( $scope.utils == null ) {
        $scope.utils = utils;
        $scope.templateContent = utils.templateContent.clone()
        $scope.userTemplateContent = utils.userTemplateContent.clone()
      } else {
        utils = $scope.utils;
      }


      $scope.errors = [];
      var element = utils.element;
      var $compile = utils.$compile;

      var scope = $scope;

      utils.templateContent = $scope.templateContent.clone()
      utils.userTemplateContent = $scope.userTemplateContent.clone()


      var ret = $scope.getFormObjects()
      var formObject = ret.formObject;
      var dataObject = ret.dataObject;

      scope.dataObject= dataObject;
      scope.formObject= formObject;

      console.info('quickform', 'render', dataObject, formObject, scope.vm.config )


      var qFName = 'qfX'+sh.randomizeInt();
      var form = angular.element('<form name="'+qFName+'"></form>');

      form.attr('name', 'userForm2');


      var helper = {};
      //for each option, ensure it has a name and value, if just a string
      helper.fixOptions = function fixOptions(fieldInfo) {
        if ( angular.isFunction(fieldInfo.fxOptions ) ) {
          try {
            fieldInfo.options = fieldInfo.fxOptions(scope.dataObject, fieldInfo);
          } catch ( e ) {
            console.error('quickform', 'could not convert fx to options', fieldInfo)
            fieldInfo.options = [];
          }
        }

        if ( fieldInfo.options == null ) {
          return;
        }
        if ( fieldInfo.options.length == 0 ) {
          return;
        }
        //check if first option is a string
        var firstOption = fieldInfo.options[0];
        if ( firstOption.name != null ) {
          return
        }
        var fixedOptions = [];
        sh.each(fieldInfo.options, function fixOption(i, option) {
          var fixedOption = {};
          fixedOption.name = option;
          fixedOption.value = option;
          fixedOptions.push(fixedOption)
        });

        fieldInfo.options = fixedOptions;


        function distributeArrayToOptions(prop, arr) {
          if ( arr == null ) {
            return;
          }
          sh.each(fieldInfo.options, function addOption(i,opt) {
            opt[prop] = arr[i]
          })
        }
        distributeArrayToOptions('color', fieldInfo.optionsColors);
        //create css object on option for styling
        sh.each(fieldInfo.options, function addOption(i,opt) {
          opt.css = {backgroundColor:opt.color};
        });


      }
      helper.reset = function reset() {
        helper.fieldInfo = null ;
      };

      scope.fxDefaults = [];



      $.each(scope.formObject,
          function addFormElement(index, value) {

            //beg
            var fieldInfo = value || {};

            if ( fieldInfo.label == null ) {
              fieldInfo.label = index;
              // insert a space before all caps
              fieldInfo.label =  fieldInfo.label.replace(/([A-Z])/g, ' $1')
              // uppercase the first character
                  .replace(/^./, function(str){ return str.toUpperCase(); })
              //fieldInfo.label = fieldInfo.label.charAt(0).toUpperCase() + fieldInfo.label.slice(1);
            }


            //generate a string to access a property on the field info
            function accrFieldInfo(prop) {
              return 'formObject.' + index + '.'+prop
            };
            function bind(prop) {
              return '{{' + prop + '}}';
            };
            function accShowElementOnFieldInfo(element, prop, field) {
              //element.attr('ng-show', '!'+accrFieldInfo('hiddenComponent'));
              element.attr('ng-show', '!'+accrFieldInfo('hiddenComponent'));
              //element.attr('ng-show',  'testShow("' + index + '")');
              //element.append(' -  ' + '!'+bind(accrFieldInfo('hiddenComponent')))
              return;

            }

            var input = null;

            helper.reset();
            helper.fieldInfo = fieldInfo;
            helper.fixOptions(fieldInfo);
            helper.processed = false;
            helper.handled = function handler() {
              helper.processed = true;
            }

            var types = {}
            types = quickFormHelper.types;

            if ( angular.isString(fieldInfo.options ) ) {
              var options = fieldInfo.options.split(';');
              var options_ =[];
              for ( var i = 0; i < options.length ; i++) {
                var option = options[i];
                var option2 = option.split(',');
                var newOption = {};
                newOption.name= option2[0].trim();
                newOption.value= option2[1].trim();
                options_.push(newOption);
              }
              fieldInfo.options = options_;
            }
            function ifPropDefAddAttr(obj, prop, toObj, storeAs) {
              var val = obj[prop];
              if ( val ) {
                storeAs = sh.dv(storeAs, prop);
                toObj.attr(prop, val)
              }
            }


            var br = $('<br />');


            if ( fieldInfo.type == types.input || fieldInfo.type == null ) {
              helper.handled();
              //<div>
              var container = angular.element('<div />');
              container.addClass('form-group')
              form.append(container);

              //<label>Email</label>
              var label = angular.element('<label/>');
              label.html(fieldInfo.label);
              container.append(label); //.html(index);

              container.append(br.clone());

              //<input ng-model="user.email" type="email">
              var input = angular.element('<input/>');


              ifPropDefAddAttr(fieldInfo, 'tooltip',input, 'title')


              input.attr('ng-model', 'dataObject.' + index);
              container.append(input);
            }

            if ( fieldInfo.type == types.textArea ) {
              helper.handled();
              //<div>
              var container = angular.element('<div />');
              container.addClass('form-group')
              form.append(container);

              //<label>Email</label>
              var label = angular.element('<label/>');
              label.html(fieldInfo.label);
              container.append(label); //.html(index);

              container.append(br.clone())

              //<input ng-model="user.email" type="email">
              var input = angular.element('<textarea/>');
              ifPropDefAddAttr(fieldInfo, 'tooltip',input, 'title')
              input.attr('ng-model', 'dataObject.' + index);
              container.append(input);
            };


            if ( fieldInfo.type == types.lbl || fieldInfo.type == types.label ) { //
              helper.handled();
              if ( fieldInfo.plain == false ) {
                var container = angular.element('<div />');
                form.append(container);
                var label = angular.element('<label/>');
                if (fieldInfo.label != null) {
                  label.html(fieldInfo.label);
                }
                if (fieldInfo.field != null) {
                  label.html('' + '{{' + 'dataObject.' + fieldInfo.field + '}}');
                }
                container.append(label); //.html(index);
                accShowElementOnFieldInfo(container);
              } else {
                var label = angular.element('<label/>');
                if (fieldInfo.label != null) {
                  label.html(fieldInfo.label);
                }
                if (fieldInfo.field != null) {
                  label.html('' + '{{' + 'dataObject.' + fieldInfo.field + '}}');
                }
                accShowElementOnFieldInfo(label)
                form.append(label);

                if ( fieldInfo.addBrAfter != false ) { //why: if plain, needs a br
                  var hr = angular.element('<hr/>');
                  accShowElementOnFieldInfo(hr)
                  form.append(hr);
                }
              }

              if ( fieldInfo.hr ) {
                var hr = angular.element('<hr/>');
                accShowElementOnFieldInfo(hr)
                form.append(hr);
              }


            }


            if ( fieldInfo.type == types.br ) { //types.label

              helper.handled();
              var label = angular.element('<label/>');
              if (fieldInfo.label != null) {
                label.html(fieldInfo.label);
              }
              if (fieldInfo.field != null) {
                label.html('' + '{{' + 'dataObject.' + fieldInfo.field + '}}');
              }
              accShowElementOnFieldInfo(label)
              form.append(label);

            }

            if ( fieldInfo.type == types.button ) {
              helper.handled();
              var container = angular.element('<div />');

              form.append(container);
              var btn = angular.element('<button/>');
              btn.attr('ng-click',
                  'formObject.' + index+'.fxDefault(dataObject); '+
                  'formObject.' + index+'.fx(dataObject)');
              /*if ( fieldInfo.label != null ) {
               label.html(fieldInfo.label);
               }
               if ( fieldInfo.field != null ) {
               label.html(''+'{{'+'dataObject.'+fieldInfo.field+'}}');
               }*/
              fieldInfo.fxDefault = function () {
                console.log('fxdefault');
                if ( fieldInfo.setProp != null  ) {
                  var val = fieldInfo.label;
                  val = sh.dv(fieldInfo.val, val)
                  scope.dataObject[fieldInfo.setProp] =
                      val;
                }
              }
              btn.addClass(fieldInfo.classes);
              if ( fieldInfo.color ) {
                btn.css('background-color', fieldInfo.color );
              }
              // btn.attr('label', fieldInfo.label );
              btn.html(fieldInfo.label)
              container.append(btn); //.html(index);
              //form.append(btn);
            }
            /*
             <md-select placeholder="Pick" ng-model="someVal">
             <md-option value="1">One</md-option>
             <md-option value="2">Two</md-option>
             </md-select>
             */
            if ( fieldInfo.type == types.select ) {
              helper.handled();
              var container = angular.element('<div />');



              // <md-select placeholder="Pick" ng-model="someVal">
              var mdSelect = angular.element('<md-select />');
              mdSelect.attr('ng-model', 'dataObject.' + index);
              mdSelect.attr('placeholder', fieldInfo.label);
              container.append(mdSelect)
              form.append(container);

              //<md-option ng-repeat="selectOption in formObject.index.options" value="selectOption.value">
              //{{selectOption.name}}
              // </md-option>
              /*container.html('<md-option ng-repeat="selectOption in formObject.'+index+'.options" value="selectOption.value">' +
               '{{selectOption.name}}'+
               '</md-option>');
               container.html('<md-option ng-repeat="selectOption in formObject.'+index+
               '.options" value="selectOption.value">' +
               '{{selectOption.name}}'+
               '</md-option>');*/
              mdSelect.html('<span ng-repeat="selectOption in formObject.'+index+
                  '.options">'+'<md-option  value="{{selectOption.value}}">' +
                  '{{selectOption.name}}'+
                  '</md-option>'+'</span>');

              //<md-option value="1">One</md-option>
            }

            if ( fieldInfo.type == types.tasklist ) {
              helper.handled();
              var container = angular.element('<div />');
              // <div> can only have *one* <input> or <textarea> child element!
              var container = angular.element('<div />');
              container.css('position', 'relative');

              // <md-select placeholder="Pick" ng-model="someVal">
              var taskList = angular.element('<quick-checklist />');
              //taskList.attr('ng-model', 'dataObject.' + index);
              //taskList.attr('placeholder', fieldInfo.label);
              //Set data on component
              var tConfig = {};
              fieldInfo.tConfig = tConfig;
              tConfig.settings = {
                showSettingsButton:false,
                showCompletedSeperate:true,
                showBringToTop:true,
                showBottomRow:false,
                showViewSwitcher:true}
              tConfig.fxChange = function (newVal) {
                $scope.dataObject.data = newVal;
                console.log('changed string ....')
              }
              tConfig.data = sh.dv($scope.dataObject.data, '');
              $scope.taskListConfig = tConfig;
              taskList.attr('config', "taskListConfig");
              container.append(taskList)
              form.append(container);
              console.log('changed string ....', tConfig.data);

              function fxSetInitialValueOfTaskList() {
                var val = $scope.utils2.getVal(index);
                console.error('tasklist')
                tConfig.data = sh.dv(val, '');
                if ( tConfig.fxRefresh != null ) {
                  tConfig.fxRefresh();
                }
              }
              //fxSetInitialValueOfTaskList();
              scope.fxDefaults.push(fxSetInitialValueOfTaskList);


            }

            /*
             <p>Selected Value: <span class="radioValue">{{ data.group1 }}</span> </p>
             <md-radio-group ng-model="data.group1">
             <md-radio-button value="Apple" class="md-primary">Apple</md-radio-button>
             <md-radio-button value="Banana"> Banana </md-radio-button>
             <md-radio-button value="Mango">Mango</md-radio-button>
             </md-radio-group>
             <hr />
             */
            if ( fieldInfo.type == types.radio ) {
              helper.handled();
              var container = angular.element('<div />');
              form.append(container);
              //<md-radio-group ng-model="data.group1">
              var containerRG = angular.element('<div />');
              container.append(containerRG);
              containerRG.attr('ng-model', 'dataObject.' + index);
              //containerRG.attr('placeholder', fieldInfo.label);
              containerRG.html(
                  '<div class="radio" ng-repeat="radioOption in formObject.'+index+
                  '.options">'+
                   '<label>'+
                  '<input type="radio"  value="{{radioOption.value}}">' +
                  '{{radioOption.name}}'+
                  '</label>'+
                  '</div>');
            }


            if ( fieldInfo.type == types.buttonroll ) {
              helper.handled();
              var container = angular.element('<div />');
              form.append(container);

              var containerCSS = {};

              if ( fieldInfo.noGutterSpace == true ) {
                containerCSS['padding-bottom'] ='0px';
                containerCSS['margin-bottom'] ='-14px';
              }
              var containerCss = 'ng-style=\'' +
                  JSON.stringify(containerCSS)+'\'';

              var accFormObjectField = 'formObject.'+index

              var repeater =  'ng-repeat="radioOption in formObject.'+index+
                  '.options"'
              var ngClick = 'formObject.' + index+'.fxDefault('+('radioOption')+'); '
              if ( fieldInfo.fx != null ) {
                ngClick += 'formObject.' + index + '.fx(dataObject)'
              }
              //ngClick = "alert('sdf')"
              ngClick = ' ng-click="' + ngClick +  '" ';
              //var radioOptionName = sh.qq('radioOption.name');

              var ngClass = ''
              ngClass = fieldInfo.classes;
              ngClass = ' ngClass="' + ngClass +  '" ';

              var btnCSS = {};

              if ( fieldInfo.color != null  ) {
                btnCSS['background-color'] =fieldInfo.color;
              }
              var buttonCss = " ng-style='" + JSON.stringify(btnCSS)+"' ";
              var buttonCss = " ng-style='" + 'radioOption.css'+"' ";

              //var hide = transcludeHelper.utils.htmlAttr('ng-show', '');

              var hide = '';
              var buttonRollHTML = "<div "+hide+repeater+ containerCss + " >" +
                  '<md-button '+ngClick+ngClass+buttonCss + '>'+
                  '{{radioOption.name}}' + //+'{{formObject.' + index+'.fxDefault}}' +
                  //'<br />{{formObject.' + index+'}}' +
                  '<span ng-if="radioOption.selected"> (selected)</span>' +
                  '</md-button>'+
                  "</div>";

              buttonRollHTML = angular.element(buttonRollHTML);
              buttonRollHTML.attr('ng-show', 'testShow("' + index + '")');

              form.append(buttonRollHTML);
              var htmlListVals =
                  '<div ng-if="'+accFormObjectField+'.showVal">{{dataObject["'+index+'"]}}</div> ';

              htmlListVals = transcludeHelper.utils.wrap(htmlListVals, 'div'  )
              //TODO: hide the outer container
              accShowElementOnFieldInfo(htmlListVals);//.attr('ng-if', accFormObjectField+'.showVal');


              form.append(htmlListVals);
              fieldInfo.fxDefault = function fxDefaultAction (radioOption, confirmed) {
                console.log('fx-default');
                var val = radioOption.name;
                if (fieldInfo.multipleSelect != true) {
                  if (fieldInfo.selectedRadioOption != null) {
                    fieldInfo.selectedRadioOption.selected = false;
                  }
                  fieldInfo.selectedRadioOption = radioOption;
                  radioOption.selected =true;
                } else {
                  //unselect if selected
                  if ( radioOption.selected == true  ) {
                    if ( confirmed == null && fieldInfo.confirmDeselect ) {
                      dialogService.showConfirm(
                          'Are you sure you want to unselect?',
                          'This cannot be undone', [fxDefaultAction,radioOption,true]);
                      return;
                    }
                    radioOption.selected = false;
                  } else {
                    radioOption.selected = true;
                  }
                }

                var curVal = scope.dataObject[index];

                if (fieldInfo.multipleSelect) {
                  curVal = sh.dv(curVal, '{}');
                  curVal = JSON.parse(curVal);
                  var selectedOptions = sh.each.find(fieldInfo.options, 'selected', true )
                  curVal = sh.each.collect(selectedOptions, 'value');
                  curVal = JSON.stringify(curVal);
                } else {
                  curVal = val
                };
                if ( fieldInfo.setSelf ) {
                  scope.dataObject[index] = curVal;
                };
                if ( fieldInfo.setProp != null  ) {
                  console.log('fxdefault' ,val);
                  scope.dataObject[fieldInfo.setProp] = curVal;
                };


                config.events.onClick(index,
                    {
                      fieldInfo:fieldInfo,
                      val:curVal,
                      dataObject:$scope.dataObject
                    }
                );

              }
              //fieldInfo.fxDefault = 'sdfd'
              //   btn.addClass(fieldInfo.classes);
              var style = {};
              if ( fieldInfo.color ) {
                style['background-color'] = fieldInfo.color;
              }
              // btn.attr('label', fieldInfo.label );
              // btn.html(fieldInfo.label)
              // container.append(btn); //.html(index);
              // container.attr('ng-model', 'dataObject.' + index);
              // container.attr('placeholder', fieldInfo.label);
              /*
               container.html('<span ng-repeat="radioOption in formObject.'+index+
               '.options">'+'<md-radio-button  value="{{radioOption.value}}">' +
               '{{radioOption.name}}'+
               '</md-radio-button>'+'</span>');
               */

              //set option names ...
              function fxSetInitialLabel() {
                var curVal = scope.dataObject[index];

                if ( fieldInfo.setSelf ) {
                }
                if ( fieldInfo.setProp != null  ) {
                  curVal = scope.dataObject[fieldInfo.setProp];
                }

                if (fieldInfo.multipleSelect) {
                  curVal = sh.dv(curVal, '{}');
                  //qf.setValue, with live object, conver to JSON string
                  if ( angular.isObject(curVal)) {
                    curVal = JSON.stringify(curVal);
                  }
                  try {
                    curVal = JSON.parse(curVal)
                  }
                  catch ( e ) {
                    console.error('quickform', 'init', 'cannot convert', curVal)
                    curVal = {};
                  }
                  console.error('init multiple select', curVal);
                  var selectedOptions = sh.each.find(
                      fieldInfo.options, 'name', curVal );
                  sh.each.setProp(selectedOptions, 'selected', true );
                } else {
                  console.error('check for ', curVal);
                  var selectedOptions = sh.each.find(
                      fieldInfo.options, 'selected', curVal, true );
                  sh.each.setProp(selectedOptions, 'selected', true );
                  fieldInfo.selectedRadiOption = selectedOptions[0];
                }



                /*if ( fieldInfo.setSelf ) {
                 scope.dataObject[index] = curVal;
                 }*/
              }
              fxSetInitialLabel();
              scope.fxDefaults.push(fxSetInitialLabel);

            }

            if ( fieldInfo.type == types.boolean || fieldInfo.type == types.checkbox ) {
              helper.handled();
              var containerOuter = angular.element('<div />');
              containerOuter.addClass('form-group')
              form.append(containerOuter);
              var container = angular.element('<div />');
              container.addClass('checkbox')
              containerOuter.append(container);

              var label = angular.element('<label/>');

              //container.append(label); //.html(index);

              //<md-radio-group ng-model="data.group1">
              var checkbox = angular.element('<input />');
              checkbox.attr('type', 'checkbox')
              checkbox.attr('ng-model', 'dataObject.' + index);
              checkbox.attr('aria-label', fieldInfo.label);
              checkbox.html(fieldInfo.label);
              input = checkbox;
              label.append(checkbox);
              label.append(fieldInfo.label);
              //container.attr('placeholder', fieldInfo.label);
              container.append(label);

            }


            /*
             <input name="n"
             type="number"
             min="0"
             max="10"
             step="2"
             value="6">
             */

            /*
             if ( fieldInfo.type == types.number ||
             fieldInfo.type == types.stepper  ) {
             var container = angular.element('<input />');
             container.attr('type', 'number');
             if ( fieldInfo.min != null ) {
             container.attr('min', fieldInfo.min);
             };
             if ( fieldInfo.max != null ) {
             container.attr('max', fieldInfo.max);
             };
             container.attr('ng-model', 'dataObject.' + index);
             form.append(container);
             }
             */


            if ( fieldInfo.type == types.number ||
                fieldInfo.type == types.stepper  ) {
              var container = angular.element('<div />');
              form.append(container);

              //<label>Hourly Rate (USD)</label>
              var label = angular.element('<label/>');
              label.html(fieldInfo.label);
              container.append(label); //.html(index);

              //<input ng-model="user.email" type="email">
              var input = angular.element('<input/>');
              input.attr('ng-model', 'dataObject.' + index);
              container.append(input);

              input.attr('type', 'number');
              if ( fieldInfo.min != null ) {
                input.attr('min', fieldInfo.min);
              };
              if ( fieldInfo.max != null ) {
                input.attr('max', fieldInfo.max);
              };
              helper.handled();
            }
            if ( fieldInfo.type == types.hr   ) {
              var container = angular.element('<div />');
              //form.append(container);

              var hr = angular.element('<hr/>');
              form.append(hr);

              helper.handled();
            }
            if ( fieldInfo.type == types.hider   ) {


              //Put button in container
              var containerBtn = angular.element('<div />');

              var btn = angular.element('<md-button/>');
              btn.attr('ng-click',
                  //'formObject.' + index+'.fxDefault(dataObject); '+
                  'formObject.' + index+'.fx(dataObject)');
              btn.html('Hide ' + fieldInfo.label);
              btn.html(bind(accrFieldInfo('btnLabel')));
              containerBtn.append(btn);
              form.append(containerBtn);

              //var containerOpenTag = '<div >';
              // form.append(containerOpenTag);
              //Approach: Change form instead
              var container = angular.element('<div />');
              container.attr('ng-hide', accrFieldInfo('hidden'));
              container.attr('labelName', 'hiderFor '+fieldInfo.label);

              form.append(container);
              //switch containers
              helper.form = form;
              form= container;

              if ( fieldInfo.debug ) {
                form.append('opened2....<br/>');
                var label = angular.element('<label/>');
                label.html(fieldInfo.label);
                form.append(label);
              }

              fieldInfo.fx = function toggleHide(change) {
                if ( change != false )
                  fieldInfo.hidden = ! fieldInfo.hidden;
                if ( fieldInfo.hidden ) {
                  fieldInfo.btnLabel = ('show '+ fieldInfo.label)
                } else {
                  fieldInfo.btnLabel = ('hide '+ fieldInfo.label)
                }
                //console.log('quickform', 'togglehide', fieldInfo.hidden );
              }
              fieldInfo.hidden = false;
              //REQ: Hide on Init
              if ( fieldInfo.hidden ) {
                fieldInfo.hidden = true;
              }
              fieldInfo.fx(false);
              helper.currentHider = fieldInfo;
              helper.handled();
            }
            if ( fieldInfo.type == types.hiderClose ) {
              if ( helper.currentHider == null ) {
                throw new Error('not hiding');
              };
              helper.currentHider = null;
              helper.handled();


              if ( fieldInfo.debug ) {
                form.append('closed....<br/>');
              }
              //var containerCloseTag = '</ div >';
              //form.append(containerCloseTag)
              form = helper.form;

            }
            /*
             <div>
             <label>Email</label>
             <input ng-model="user.email" type="email">
             </div>
             */

            /*
             <div layout layout-sm="column">
             <div style="width:80%">
             <label>Company (Disabled)</label>
             <input ng-model="user.company" disabled>
             </div>
             <div flex>
             <label>Submission Date</label>
             <input type="date" ng-model="user.submissionDate">
             </div>
             </div>
             */


            /*
             <div flex>
             <label>Biography</label>
             <textarea ng-model="user.biography" columns="1" md-maxlength="150"></textarea>
             </div>
             */


            /*
             <p>Selected Value: <span class="radioValue">{{ data.group1 }}</span> </p>
             <md-radio-group ng-model="data.group1">
             <md-radio-button value="Apple" class="md-primary">Apple</md-radio-button>
             <md-radio-button value="Banana"> Banana </md-radio-button>
             <md-radio-button value="Mango">Mango</md-radio-button>
             </md-radio-group>
             <hr />
             */


            /*
             <md-select placeholder="Pick" ng-model="someVal">
             <md-option value="1">One</md-option>
             <md-option value="2">Two</md-option>
             </md-select>
             */


            //End
            //console.error('quickform', 'added', index,  fieldInfo)
            if ( fieldInfo.noGutterSpace == true ) {
              container.css('padding-bottom', '0px');
              container.css('margin-bottom', '-14px');
            }
            if ( fieldInfo.reduceGutterSpace == true ) {
              if ( container == null ) {
                console.error('no container', container, fieldInfo )
              } else {
                container.css('padding-bottom', '5px');
                container.css('margin-bottom', '-14px');
              }
            }


            if ( fieldInfo.debugConditionals ) {
              //form.append('asdf')
              //form.append( fieldInfo)
              //form.append(bind(accrFieldInfo('hiddenComponent')))
            }

            //add error pane
            if ( container != null ) {
              var messages = angular.element('<div ng-messages="qf" />')
              messages.attr('ng-show', accrFieldInfo('msgs.length>0') );
              var message  = ('<div ng-message="auto" ng-repeat="msg in formObject.'+index+
              '.msgs" >'+
              '{{msg}}' +
              '</div><br/>');
              messages.append(message);
              container.append(messages)

              //help msgs
              var messages = angular.element('<div ng-messages="qf" />')
              messages.attr('ng-show', accrFieldInfo('help.length>0') );
              var message  = ('<div ng-message="auto" style="color:black;" ng-repeat="msg in formObject.'+index+
              '.help" >'+
              '{{msg}}' +
              '</div><br/>');
              messages.append(message);
              container.append(messages);


              //debug msgs
              var style = 'style="' +  "color:black; position:absolute; right: 0px; top: 0px; opacity: 0.70; /*width:100%*/" + '"'
              var outerStyle = '';
              outerStyle= 'style="' +  " position:absolute; right: 4px; top: 4px; opacity: 0.70; width:100%" + '"'
              var messages = angular.element('<div ng-messages="qf" '+outerStyle+' />')
              messages.attr('ng-show', accrFieldInfo('help2.length>0') );
              messages.attr('ng-hide',  'vm.config.showDebug!=true'  );
              var message  = ('<div ng-message="auto" '+style+' ng-repeat="msg in formObject.'+index+
              '.help2" >'+
              '{{msg}}' +
              '</div><br/>');
              messages.append(message);
              container.append(messages);
            }

            if ( container != null ) {
              accShowElementOnFieldInfo(container);
              //container.attr('ng-show', 'testShow("' + index + '")');
              container.attr('ng-disabled', 'testDisable("' + index + '")');
              //accShowElementOnFieldInfo(container, 'ng-disabled', 'componentDisable');
            }

            if ( input != null  ) {
              if ( fieldInfo.required == true ) {
                // input.attr('required', 'true')
              }
            }

            if ( fieldInfo.defaultValue != null &&
                ( dataObject[index] === null ||
                dataObject[index] === undefined ||
                dataObject[index] === '' )
            ) {
              console.log('quickform', 'set default value',
                  index,
                  dataObject[index],
                  fieldInfo.defaultValue)
              dataObject[index] = fieldInfo.defaultValue;

            }

            if ( fieldInfo.defaultValue != null )  {
              // asdf.g

            }

            if ( helper.processed == false ) {
              console.error('QuickForm', 'did not process', fieldInfo.type, fieldInfo);
            }

          });



      $scope.utils2 = {};
      $scope.utils2.runConditions =  function runConditions(conditions, obj, defaultVal, fieldInfo) {
        defaultVal = sh.dv(defaultVal, true)
        //rename variables for convenience
        var object = obj;
        var o = obj;


        if ( conditions == null ||  conditions.length == 0  ) {
          return defaultVal;
        }
        //conditions has to be an array
        if ( conditions.length == null ) {
          console.error('issue with input to ')
          return defaultVal;
        }
        for ( var i = 0; i < conditions.length ; i++) {
          var condition = conditions[i];
          var error = null;
          try {
            var result = eval(condition)

          } catch ( e ) {
            //console.error(e.message, /*e.stack,*/ obj);
            //result = false;
            //return result;
            error = e ;
          }

          if ( error != null ) {
            return false;
          }
          //console.error('quickform', condition , result, error!=null, fieldInfo);

          //console.log('test condition',result, condition, object.prompt_type);
          if ( result == true ) {
            //console.log('test condition', 'match', result, condition)
            return true;
          }
        }
        //console.error('false')
        return false;
      }
      $scope.utils2.getVal = function getValFromFieldInfo(index) {
        var fieldInfo = $scope.formObject[index] //value || {};
        var val = $scope.dataObject[index];
        if (fieldInfo.setProp) {
          val = $scope.dataObject[fieldInfo.setProp];
        };
        return val;
      };
      $scope.utils2.getField = function getFieldFromFieldInfo(index) {
        var fieldInfo = $scope.formObject[index] //value || {};
        var field = index;
        if (fieldInfo.setProp) {
          field = fieldInfo.setProp;
        };
        return field;
      };

      function defineDynamicHandlers() {

        $scope.testShow = function (v, b) {
          if ($scope.dataObject == null) {
            return false;
          }
          var value = $scope.dataObject[v];
          var fieldInfo = scope.formObject[v];
          if ( $scope.dataObject == {} ) {
            console.log('issue ')
            return false;
          }
          if ( fieldInfo == null ) {
            //not a visible form ... ? where does this come from?
            //console.log('issue fieldInfo null')
            return false;
          }
          fieldInfo.hiddenComponent = false;
          if ( fieldInfo != null ) {
            var conditions = fieldInfo.showIf;
            //console.log('fieldInfo', fieldInfo.label);//, $scope.dataObject, scope.dataObject, scope)
            var result = $scope.utils2.runConditions(conditions, $scope.dataObject, null, fieldInfo);
            if ( fieldInfo.debugConditionals == true ) {
              console.log('quickform', 'conditions', fieldInfo, conditions, result )
            }
            //console.error('quickform','cond', fieldInfo.label , result, conditions  );
            fieldInfo.hiddenComponent = ! result;
            if ( result ) {
              return true;
            } else {
              return false;
            }
          }
          //this should be first
          /*if ( fieldInfo != null ) {
           var conditions = fieldInfo.hideIf;
           var result = runConditions(conditions, $scope.dataObject);
           if ( result ) {
           return false;
           }
           }*/
          //console.log('testShow', v, b, fieldInfo);
          return true;
        };

        $scope.testDisable = function (v, b) {
          if ($scope.dataObject == null) {
            return false;
          }
          var value = $scope.dataObject[v];
          var fieldInfo = scope.formObject[v];
          if ( fieldInfo != null ) {
            var conditions = fieldInfo.disabledIf;
            var result = $scope.utils2.runConditions(conditions, $scope.dataObject, false);
            if ( result ) {
              return true;
            }
            return false;
          }
          //console.log('testDisable', v, b, fieldInfo);
          return false;
        };

      }
      defineDynamicHandlers();


      $scope.setDefaults= function setDefaults() {
        var dataObject = $scope.dataObject;
        $.each(formObject,
            function addFormElement(index, fieldInfo) {
              if ( fieldInfo.defaultValue != null &&
                  ( dataObject[index] === null ||
                  dataObject[index] === undefined ||
                  dataObject[index] === '' )
              ) {
                console.log('quickform', 'set default value',
                    index,
                    dataObject[index],
                    fieldInfo.defaultValue);
                dataObject[index] = fieldInfo.defaultValue;
              }

              helper.fixOptions(fieldInfo);

            });

        $scope.testForHiddenElements();
        sh.each(scope.fxDefaults, function proc(i, fx ) {
          try {
            fx();
          } catch ( e ) {
            console.error('cannot run fxDefault', e.message, e.stack, fx.name)
          }
        })

      }


      $scope.testForHiddenElements = function testForHiddenElements() {
        function testFieldInfo(i, fieldInfo) {
          if ( fieldInfo == null ) {
            fieldInfo = i;
          }
          if ( fieldInfo.hiddenComponent == null ) {
            fieldInfo.hiddenComponent = false;
          }
          if (fieldInfo != null) {
            var conditions = fieldInfo.showIf;
            //console.log('fieldInfo', fieldInfo.label);//, $scope.dataObject, scope.dataObject, scope)
            var result = $scope.utils2.runConditions(conditions, $scope.dataObject, null, fieldInfo);
            if (fieldInfo.debugConditionals == true) {
              console.log('quickform', 'conditions', fieldInfo, conditions, result)
            }
            //console.error('quickform','cond', fieldInfo.label , result, conditions  );
            fieldInfo.hiddenComponent = !result;

            return; //do not return false ... will exit loop
            if (result) {
              return true;
            } else {
              return false;
            }
          };
        };

        sh.each(formObject, testFieldInfo);
      }

      $scope.userChangedForm = function userChangedForm(defaultAction) {
        $.each(formObject,
            function handleDynamicMethods(index, value) {
              var fieldInfo = value || {};
              //invoke dynamic change handler
              if ( fieldInfo.fxChange != null ) {
                console.log('...j')
                var val = $scope.dataObject[index];
                if ( fieldInfo.setProp ) {
                  val = $scope.dataObject[fieldInfo.setProp];
                }
                fieldInfo.fxChange($scope.dataObject, fieldInfo, val, $scope.formObject);
              };

              /**
               * Convert options into name/value pairs if
               * string only.
               * @param fieldInfo
               */
              function fixOptions(fieldInfo) {
                if ( fieldInfo.options == null ) {
                  return;
                }
                if ( fieldInfo.options.length == 0 ) {
                  return;
                }
                var firstOption = fieldInfo.options[0];
                if ( firstOption.name != null ) {
                  return
                }
                var fixedOptions = [];
                sh.each(fieldInfo.options, function fixOption(i, option) {
                  var fixedOption = {};
                  fixedOption.name = option;
                  fixedOption.value = option;
                  fixedOptions.push(fixedOption)
                });
                fieldInfo.options = fixedOptions;
              }
              fixOptions(fieldInfo);

            });

        //grab validation errors
        $scope.errors = [];
        $.each(formObject,
            function checkValidations(index, value) {
              var fieldInfo = value || {};

              var val = $scope.utils2.getVal(index);
              fieldInfo.msgs = [];

              var blank = val == null || val == ''
              if ( fieldInfo.required && blank && fieldInfo.hiddenComponent == false ) {
                //console.log('x', val)
                var requiredMsg = 'This field is required';
                if ( fieldInfo.requiredMsg ) {
                  //debugger;
                  requiredMsg = fieldInfo.requiredMsg;
                }
                fieldInfo.msgs.push(requiredMsg);
                $scope.errors.push({fieldInfo:fieldInfo})
              };


            });

        //renumber all elements ...
        var count = 0;
        var countInput = 0;
        var countVisible = 0;
        $.each(formObject,
            function checkValidations(index, value) {
              var fieldInfo = value || {};
              var val = $scope.dataObject[index];

              count++;
              fieldInfo.indexCount=count;
              if ( ! quickFormHelper.utils.inputType( fieldInfo) ) {
                return;
              };

              countInput++;
              fieldInfo.indexCountInput = countInput;
              if ( fieldInfo.hiddenComponent ) {
                return;
              };

              countVisible++;
              fieldInfo.indexCountVisible = countVisible;

            });
        $.each(formObject,
            function checkValidations(index, value) {
              var fieldInfo = value || {};
              fieldInfo.help2 = [];
              fieldInfo.help2.push([fieldInfo.label, fieldInfo.indexCount, count,
                ' ',
                fieldInfo.indexCountInput, countInput,
                ' ',
                fieldInfo.indexCountVisible, countVisible
              ].join(' '))

              /* if () {

               }*/

            });


        $scope.testForHiddenElements();

        //REQ: Invoke dynamic methods after change
        $.each(formObject,
            function handleDynamicMethods_Post(index, value) {
              var fieldInfo = value || {};
              //invoke dynamic change handler
              if (fieldInfo.fxChange2 != null) {
                var val = $scope.utils2.getVal(index)

                fieldInfo.fxChange2($scope.dataObject, fieldInfo, val);
              };

            });



        function dispatchEventsForChangedProperties() {
          //REQ: Dispatch events on config;
          sh.each($scope.dataObject, function processI(prop, val) {
            var prevVal = $scope.previousDataObject[prop];
            if ( prevVal != val ) {
              if ( config.events == null ) {
                return;
              }
              config.events.onChange(prop, val, prevVal);
              //console.log('new event', $scope.id, element,
              //  prop, prevVal, val );
            }
          });
        };
        if ( $scope.previousDataObject != null ) {
          dispatchEventsForChangedProperties();
        }
        $scope.previousDataObject = sh.clone($scope.dataObject);

      };

      //utils.templateContent.find('#bodyContent').append(form);
      utils.templateContent.find('#bodyContent').append(form);


      var config = scope.vm.config;
      if ( config == null ) { config = {} }
      //removes centering of footer buttons
      if ( config.btnRowNoCenter == true ) {
        utils.templateContent.find('#btnRow').removeAttr('layout-sm');
        utils.templateContent.find('#btnRow').removeAttr('layout-align');
      }
      utils.ifFalseHide(config.showFooter, '#btnRow');

      //REQ: store references for external saving
      config.fxSave2 = function onSaveExternally(fxDone) {
        $scope.saveFormData(fxDone);
      }

      config.fxChangeDataObject = function fxChangeDataObject(asdf) {
        $scope.vm.config.dataObject = asdf; 
        $scope.render()
      }

      var html = utils.templateContent[0];
      console.log('quickform pre-html output', utils.templateContent.clone()[0] ); //.toString() ); //.clone());



      //element.empty();
      element.html($compile(html)(scope));
      scope.element = element;
      console.log('quickform html output', html);

      $scope.setDefaults(); //force run 1 time

      /* angular.element('#btnSave').on('click', function () {
       //console.log('click ... save');
       console.log('on save');
       scope.saveFormData();
       //$rootScope.$broadcast('global:resize');
       })*/
    }



  }


  if ( window.reloadableHelper ) {
    function defineQuickReloadingDir() {
      var app = angular.module('com.sync.quick');
      window.reloadableHelper.upgradeApp(app)
      return app;

    }
    var _app = defineQuickReloadingDir()
    _app
        .reloadableController(reload_name+'Ctrl',
            quickForm2Controller2);

    //console.log('reload', app.reloadableDirective)
    _app
        .reloadableDirective(reload_name, quickForm2);
  } else {
    //debugger;
    app.controller(reload_name+'Ctrl',
        quickForm2Controller2);

    app.directive(reload_name, quickForm2);
  }

}());

