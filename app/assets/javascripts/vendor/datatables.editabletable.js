(function ($) {
    $.fn.editableTable = function (options){

        var tableId = $(this).attr('id'),
            editElementClass = options['editElementClass'],
            newElementId = options['newElementId'],
            deleteElementClass = options['deleteElementClass'],
            oTable = $(this).dataTable(),
            editUrl = options['editUrl'],
            newUrl = options['newUrl'],
            deleteUrl = options['deleteUrl'],
            columns = options['aoColumns'];

        function generateSelectHtml(optionsObject, attributes){
            var selectHtml = (attributes === undefined) ? '<select>': ('<select ' + attributes + '>');

            for(var key in optionsObject) {
                selectHtml += "<option value=" + key  + ">" +optionsObject[key] + "</option>"
            }
            selectHtml += "</select>";
            return selectHtml;
        }

        function getCellHeader(td){
            return td.closest('table').find('th').eq(td.index());
        }

        function getObjectPropertiesValues(obj){
            var dataArray = [];
            for(var propt in obj)
                dataArray.push(obj[propt]);
            return dataArray;
        }

        function capitaliseFirstLetter(string){
            return string.charAt(0).toUpperCase() + string.slice(1);
        }

        function getObjectPropertyValueAtIndex(obj, index){
            return obj[Object.keys(obj)[index]];
        }

        function getObjectPropertyKeyAtIndex(obj, index){
            return Object.keys(obj)[index];
        }

        function restoreRow(oTable, nRow) {
            var aData = oTable.fnGetData(nRow),
                oldValues = getObjectPropertiesValues(aData),
                jqTds = $('>td', nRow);

            for (var i = 0, iLen = jqTds.length; i < iLen; i++) {
                oTable.fnUpdate(oldValues[i], nRow, i, false);
            }
            oTable.fnDraw();
        }

        function editRowRevised(oTable, nRow){
            var aData = oTable.fnGetData(nRow),
                jqTds = $('>td', nRow),
                length = aData.length;

            for (var i = 0; i < (length - 2); i++){
                if(columns[i] === undefined)
                    break;
                var columnOptions = columns[i];

                if(columnOptions.editable === false)
                    continue;

                var tdElement = $(jqTds[i]),
                    parentWidth = tdElement.width(),
                    type = columnOptions.type;

                if(type === 'select'){
                    var data = columnOptions.data;
                    jqTds[i].innerHTML = generateSelectHtml(data, 'style="width: '
                        + parentWidth + 'px"');

                    var currentValue = $('.' + columnOptions.serverName).val(),
                        selectElement = tdElement.find('select');

                    selectElement.val(currentValue);

                    selectElement.change({ serverName : columnOptions.serverName }, function(e) {
                        $('.' + e.data.serverName).val($(this).val());
                    });
                } else if(type === 'text' || type === 'datepicker' || type === 'autocomplete') {
                    jqTds[i].innerHTML = '<input style="width:'
                    + parentWidth + 'px" type="text" value="'
                    + aData[i] + '">';

                    var inputElement = tdElement.find('input');
                    if(type === 'datepicker') {
                        inputElement.datepicker({
                            dateFormat: 'yy/mm/dd'
                        });
                    } else if(type === 'autocomplete') {

                        var autocompleteData = columnOptions.data;
                        var formatedAutocompleteData = new Array();
                        length = autocompleteData.length;
                        for(var propt in autocompleteData)
                            formatedAutocompleteData.push(
                                {
                                    id : propt,
                                    value : autocompleteData[propt]
                                }

                            );

                        function format(item) {
                            return item.value;
                        };
                        inputElement.select2({
                            allowClear: true,
                            data: {
                                results: formatedAutocompleteData,
                                text: 'value'
                            },
                            formatSelection: format,
                            formatResult: format
                        });

                        inputElement.on("select2-selecting", null, { serverName : columnOptions.serverName }, function(e) {
                            $('.' + e.data.serverName).val(e.val);

                        });

                        tdElement.find('.select2-chosen').text(aData[i]);
                    }
                }
            }

            $(jqTds[length - 2]).find('.' + editElementClass).text('Save');
            var deleteElement = $(jqTds[length - 1]).find('.' + deleteElementClass);
            deleteElement.attr('class', 'cancel');
            deleteElement.text('Cancel');
        }


        function saveRow(oTable, nRow) {
            var jqTds = $('>td', nRow);
            $.each(jqTds, function(index, value) {
                var element = $(this),
                headerTitle = getCellHeader(element).attr('title'),
                updateText;

                if(headerTitle === 'autocomplete' || headerTitle === 'autocomplete_dependant'){
                    updateText = element.find('.select2-chosen').text();
                } else {
                    var childElement = element.children().first();

                    if(childElement.is('div') && childElement.attr('id').indexOf('s2id') != -1){
                        updateText = childElement.find('.select2-chosen').text();
                    } else if(childElement.is('input')){
                        updateText = childElement.val();
                    }
                }

                if(updateText !== undefined)
                    oTable.fnUpdate(updateText, nRow, index, false);
            });

            $('a.edit', nRow).replaceWith('<a class="edit" href="">Edit</a>');
            $('a.cancel', nRow).replaceWith('<a class="delete"></a>');


            var aData = oTable.fnGetData(nRow),
                postData = {
                    sku: aData[0],
                    price: aData[3],
                    quantity: aData[4]
                }

            var row = $(nRow);
            var newValuesRevised = { };

            $.ajax({
                type:"PATCH",
                dataType: "json",
                url: editUrl,
                data: postData,
                complete: function(result)
                {
                    oTable._fnAjaxUpdate()
                }
            });
        }

        function cancelEditRow(oTable, nRow) {
            var jqInputs = $('input', nRow);

            var length = jqInputs.length;
            for (var i = 0; i < length; i++) {
                oTable.fnUpdate(jqInputs[i].value, nRow, i, false);
            }
            oTable.fnUpdate('<a class="edit" href="">Edit</a>', nRow, length, false);
            oTable.fnDraw();
        }

        var nEditing = null;


        $("#" + tableId).on('click', '.cancel', function (e) {
            e.preventDefault();

            if ($(this).attr("data-mode") == "new") {
                var nRow = $(this).parents('tr')[0];
                oTable.fnDeleteRow(nRow);
            } else {
                restoreRow(oTable, nEditing);
            //nEditing = null;
            }
            nEditing = null;
        });

        //edit
        $("#" + tableId).on('click', '.' + editElementClass, function (e) {
            e.preventDefault();

            /* Get the row as a parent of the link that was clicked on */
            var nRow = $(this).parents('tr')[0];

            if (nEditing !== null && nEditing != nRow) {
                /* Currently editing - but not this row - restore the old before continuing to edit mode */
                restoreRow(oTable, nEditing);
                editRowRevised(oTable, nRow);
                nEditing = nRow;
            } else if (nEditing == nRow && this.innerHTML == "Save") {
                /* Editing this row and want to save it */
                saveRow(oTable, nEditing);
                nEditing = null;
            } else {
                /* No edit in progress - let's start one */
                editRowRevised(oTable, nRow);
                nEditing = nRow;
            }
        });
    }



})(jQuery);