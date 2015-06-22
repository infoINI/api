var restler = require('restler-q');
var request = require('request');
var Q = require('q');
var crypto = require('crypto');

var authKey = 'cd12744bf5c6d9f5816cba58bc17e57091c4492c';

var getGroupMembers = function (groupID) {
    var url = 'http://infoini.de/redmine/groups/' + groupID + '.json';
    return restler.get(url, {
        headers: {
            'X-Redmine-API-Key': authKey
        },
        query: {
            include: 'users',
            key: authKey
        }
    });
};

var getUserDetails = function (userID) {
    var url = 'http://infoini.de/redmine/users/' + userID + '.json';
    return restler.get(url, {
        headers: {
            'X-Redmine-API-Key': authKey
        },
    });
};

var getCustomFieldValue = function (customFields, fieldName) {
    var i;
    for (i = 0; i < customFields.length; i++) {
        if (customFields[i].name === fieldName && customFields[i].value) {
            return customFields[i].value;
        }
    }
    return '';
};


var getMembers = function (groupId) {

    // get fsr members
    return getGroupMembers(groupId).then(function (result) {
        return Q.all(result.group.users.map(function (user) {
                return getUserDetails(user.id);
        }));
    }).then(function (results) {
        var members = [];
        results.map(function (result) {
            var user = result.user;
            members.push({
                id: user.id,
                firstname: user.firstname,
                lastname: user.lastname,
                email: user.mail,
                photo_url: 'http://infoini.de/redmine/account/get_avatar/' + user.id,
                course_of_study: getCustomFieldValue(user.custom_fields, 'Studiengang'),
                position: getCustomFieldValue(user.custom_fields, 'Aufgaben')
            });
        });
        return members.sort(function (a, b) {
            console.log('sort');
            return a.firstname.localeCompare(b.firstname);
        });
    }).then(function (members) { // check photo urls
        return Q.all(members.map(function (member) {
            var d = Q.defer();
            var r = request({ url: member.photo_url, method: 'HEAD' }, function (error, response, body) {
                var hash;
                if (error || response.statusCode != 200) {
                    //member.photo_url = 'http://infoini.de/photos/photos/FSRler/default.png';
                    hash = crypto.createHash('md5').update(member.email).digest('hex');
                    member.photo_url = 'http://www.gravatar.com/avatar/' + hash + '?s=200&d=retro';
                }
                console.log(member);
                d.resolve(member);
            });
            return d.promise;
        }));
    });
};

var groupIdFsr = 158;
var groupIdHelpers = 478;

module.exports = {
    getFSR: function () {
        return getMembers(groupIdFsr);
    },
    getHelpers: function () {
        return getMembers(groupIdHelpers);
    }
};
