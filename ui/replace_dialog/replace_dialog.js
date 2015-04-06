$(document).on('stonehearthReady', function()
{
   App.RemplaceReplaceItemsDialog = App.View.extend({
      templateName: 'replaceItemsDialog',
      closeOnEsc: true,
      
      replacerName: null,
      replaceeName: null,
      
      didInsertElement: function() {
         var self = this;
         self._super();
         
         self._buildSelectedList();
         self._buildAvailableList();
         
         $('#replaceButton').click(function() { self._replace(); });
      },
      
      readyToReplace: function()
      {
         return this.get('replacerName') && this.get('replaceeName');
      }.property('replacerName', 'replaceeName'),
      
      _buildSelectedList : function()
      {
         var self = this;
         this._selectedPalette = this.$('#selectedList').stonehearthItemPalette({
            cssClass: 'shopItem',
            
            itemAdded: function(itemEl, itemData) {
               itemEl.attr('cost', itemData.cost);
               itemEl.attr('num', itemData.num);
            },
            click: function(item) {
               self.set('replaceeName', item.attr('title'));
               self.replaceeUri = item.attr('uri');
            }
         });
         
         this._selectedPalette.stonehearthItemPalette('updateItems', this.get('items'));
      },
      
      _buildAvailableList : function()
      {
         var self = this;
         this._availablePalette = this.$('#availableList').stonehearthItemPalette({
            cssClass: 'shopItem',
            itemAdded: function(itemEl, itemData) {
               itemEl.attr('cost', itemData.cost);
               itemEl.attr('num', itemData.num);
            },
            
            click: function(item) {
               self.set('replacerName', item.attr('title'));
               self.replacerUri = item.attr('uri');
            }
         });
         
         radiant.call('remplace:get_available_items')
         .done(function(response) {
            self._availablePalette.stonehearthItemPalette('updateItems', response.items);
         })
         .fail(function(response) {
            console.error(response);
         });         
      },
      
      _replace : function()
      {
         if (!this.get('readyToReplace'))
            return;
         
         
         radiant.call('remplace:replace_items', this.get('items')[this.replaceeUri].items, this.replacerUri);
         this.destroy();
      }
   });
});
