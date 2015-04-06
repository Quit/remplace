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