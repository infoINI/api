var express = require('express');
var app = express();
var net = require('net');
var http = require('http');

var members = require('./members.js');


jRespond = function(res,data) {
        res.contentType('application/json');
        res.charset = 'utf-8';
        res.end(JSON.stringify(data));
};

var cafeStatus = {};
var tuerStatus = {};

setInterval(function() {
        var req = http.request({
                host:'iniwlan.beuth-hochschule.de',
                port:4000,
                path:'/'
        },function(res) {
                res.on('data', function(data) {
                        cafeStatus = JSON.parse(data);
                        cafeStatus.status = undefined;
                });
        });
        req.on('error',function() {
                console.error('request error');
        });
        req.end();
},
1000);

setInterval(function() {
        var client = new net.Socket();

        client.on('data', function(data) {
                pyStatus = JSON.parse(data);
                tuerStatus.status = pyStatus.tuer_offen?'OPEN':'CLOSED';
                client.destroy();
        });
        client.on('error',function(e) {
                console.error('error', e);
        });
        client.on('timeout',function() {
                console.error('timeout');
        });
        client.connect(51966, 'localhost', function() {
                // connected
        });
},
1000);

// compatibility for infoini app
app.get('/api/status.xml', function(req, res){
    console.log('get status.xml');
    console.log(cafeStatus);

    var xml = '<?xml version="1.0" encoding="UTF-8"?>'
            + '<infoini><door isOpen="' + tuerStatus.status + '" />'
            + '<cafe>'
            + '<pot>'
            + '<status>' + cafeStatus.pots[0].status + '</status>'
            + '<level>' + cafeStatus.pots[0].level + '</level>'
            + '</pot>'
            + '<pot>'
            + '<status>' + cafeStatus.pots[1].status + '</status>'
            + '<level>' + cafeStatus.pots[1].level + '</level>'
            + '</pot>'
            + '</cafe>'
            + '</infoini>';

    res.contentType('text/xml');
    res.charset = 'utf-8';
    res.end(xml);
});

app.get('/api/combined.json', function(req, res){
    console.log('get combined');
        var combined = {};
        combined.pots = cafeStatus.pots;
        combined.status = tuerStatus.status;
        jRespond(res, combined);
});

app.get('/api/members.json', function (req, res) {
    members.getFSR().then(function (members) {
        jRespond(res, { members: members});
    });
});

app.get('/api/helpers.json', function (req, res) {
    members.getHelpers().then(function (members) {
        jRespond(res, { members: members});
    });
});

app.get('/api/cafe.json', function(req, res){
    console.log('get cafe');
    jRespond(res, cafeStatus);
});

app.get('/api/door.json', function(req, res){
    console.log('get door');
    jRespond(res, tuerStatus);
});

app.get('/api/zuendstoff.pdf', function(req, res){
    console.log('get zuendstoff');
    res.redirect('http://infoini.de/redmine/attachments/download/422/zs-ss2015.pdf');
    res.end();
});

app.use("/api", express.static(__dirname + '/static'));
app.listen(3000);

