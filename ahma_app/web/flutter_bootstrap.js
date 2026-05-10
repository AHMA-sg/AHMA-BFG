{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const hostElement = document.querySelector('#flutter-phone-frame');
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: hostElement,
    });

    hostElement.querySelector('.loading-label')?.remove();
    await appRunner.runApp();
  }
});
