// This is for app/views/content/book-a-bartender.html.erb
// We should think about where we should be including this module

function initModuleLinks(){
  const $modules = $('.module[data-url]');
  $modules.each((i, module) => {
    $(module).click(e => {
      const $module = $(e.target).closest('.module');
      const url = $module.data('url');
      window.location = url;
    });
  });
}

export default initModuleLinks;
