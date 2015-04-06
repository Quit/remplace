var replaceWindowModal; // TODO: Let the Dialog handle that himself (singleton approach)?

// This is really, really ugly, but sadly, not really avoidable.
// As of A9R256, there's a JSON to mixin commands into the start menu,
// but no way to actually have them trigger anything.
// start_menu_activated is called whenever the start menu is changing; luckily,
// this seems to happen during the initialization too - not that we'd care, because
// as long as we can register our command before someone presses the button,
// we're good.
$(top).one('start_menu_activated', function()
{
   // Get the StartMenu-view
   var startMenuView = Ember.View.views[$('#startMenu').parent().attr('id')];
   
   console.debug(startMenuView);
   if (!startMenuView)
      return;
   
   startMenuView.menuActions['replace_items'] = function()
   {
      var tip = App.stonehearthClient.showTip('Replace items within an area', 'Drag the area that contains the items you want replaced.', { i18n: false });

      var self = App.stonehearthClient;
      return self._callTool('createStockpile', function() {
         return radiant.call('remplace:select_area')
            .done(function(response) {
               if (replaceWindowModal)
                  replaceWindowModal.destroy();
               
               replaceWindowModal = App.gameView.addView(App.RemplaceReplaceItemsDialog, { items: response.items });
            })
            .always(function(response) {
               self.hideTip(tip);
            });
      });
   }
});

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