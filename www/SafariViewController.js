var exec = require('cordova/exec');

module.exports = {
    isAvailable: function (success, error) {
        exec(success, error, 'SafariViewController', 'isAvailable', []);
    },

    show: function (options, success, error) {
        exec(success, error, 'SafariViewController', 'show', [options || {}]);
    },

    hide: function (success, error) {
        exec(success, error, 'SafariViewController', 'hide', []);
    },

    connectToService: function (success, error) {
        exec(success, error, 'SafariViewController', 'connectToService', []);
    },

    warmUp: function (success, error) {
        exec(success, error, 'SafariViewController', 'warmUp', []);
    },

    mayLaunchUrl: function (options, success, error) {
        exec(success, error, 'SafariViewController', 'mayLaunchUrl', [options || {}]);
    }
};