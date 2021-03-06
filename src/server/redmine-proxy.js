//credits: code@uvwxy.de
var request = require('request');

var PropertiesReader = require('properties-reader');
var properties = PropertiesReader('./kanbanboard.properties');

module.exports = (function (){

    //Config constants
    var config = {
      redmineRoot: 'https://'+properties.get('redmine.api.url')+'/',
      redmineHost: properties.get('redmine.api.url')
    };

    //API functions

    //remove empty filters
    //sometimes we expect filters and they aren't sent
    function removeEmptyFilters(filters){
        for(var prop in filters) {
            if(filters[prop] == null || !filters[prop].trim()) {
                delete filters[prop];
            }
        }
    }

    //filter issues
    function filterIssues(issues, filters) {
        var filteredIssues = issues.filter(function(issue){
            for(var prop in filters) {
                if(issue[prop] != filters[prop])
                    return false;
            }
            return true;
        });
        return filteredIssues;
    }

    //will add a map of the custom fields by name to the issue
    //it is easier to search by name than id
    function mapCustomFields(issues) {
        issues.forEach(function (issue) {
            if (issue.custom_fields) {
                issue.custom_fields.forEach(function (field) {
                    issue['cf_' + field.name] = field.value;
                });
            }
        });
    }

    //adds parameters to the redmine url
    //path is the path to add after the root redmine url
    function buildUrl(parameters, path) {
        var url = config.redmineRoot + path + '?';
        for(var prop in parameters) {
            url += prop+'='+parameters[prop]+'&';
        }
        return url.substring(0, url.length - 1); //removing the last character
    }

    //create multiple url requests and wait for all
    //usage: multipleUrlQuery(['path1','path2']).then(function(data){//do something here});
    //just like a promises
    function multipleUrlQuery(urls) {
        var results = [];
        var listener = null;
        var promise = {
            then: function(callback){
                listener = callback;
                if(results.length == urls.length) {
                    listener(results);
                }
            }
        };

        urls.forEach(function(url){
            request.get({url: url, json: true}, function(error, response, data){
                if (!error && response.statusCode === 200) {
                    results.push(data);
                }
                else {
                    results.push({error: 'data: ' + data + ', error: ' + error});
                }

                if(results.length == urls.length) {
                    listener && listener(results);
                }
            });
        });

        return promise;
    }


    //this will get data from multi issue urls
    // redmine/issues/4351.json , redmine/issues/1533.json   and so on..
    // and collect them to a single data result
    function redmineMultipleIssuesQuery(req, res, remoteFilters, localFilters, tickets) {
        var urls = null;
        if(req.query && req.query.key) {
            urls = tickets.map(function (ticket) {
                return buildUrl(remoteFilters, 'issues/' + ticket + '.json');
            });
            multipleUrlQuery(urls).then(function(results){
                //post processing of the results
                var issues = results.filter(function(data){
                    return data.issue;
                }).map(function(data){
                    return data.issue;
                });
                mapCustomFields(issues);
                //returning an answer
                res.json({issues: issues, config: config, total: issues.length});
            });
        }
        else {
            res.json({error: 'API key is missing'});
        }
    }

    function redmineAllPagesQuery(req, res, remoteFilters, localFilters, path, removeEmptyStrings) {
        var results = [];
        function callback(error, response, data){
            if (!error && response.statusCode === 200) {
                results.push(data);

                //there are so many pages
                if(data.offset + data.limit < data.total_count){
                    //lets update the filters to get the next page
                    remoteFilters.offset += data.limit;

                    //recursive call with the next page
                    var url = buildUrl(remoteFilters, 'issues.json');
                    request({url: url, json: true}, callback);
                }
                else {
                    //done
                    //now post processing
                    var issues = [];
                    results.filter(function(data){
                        return data.issues;
                    }).forEach(function(data){
                        issues = issues.concat(data.issues);
                    });
                    mapCustomFields(issues);
                    issues = filterIssues(issues, localFilters);
                    res.json({issues: issues, total: issues.length, redmine_total: data.total_count, config: config});
                }
            }
            else {
                results.push({error: 'data: ' + data + ', error: ' + error});
            }
        }

        if(localFilters && removeEmptyStrings) {
            removeEmptyFilters(localFilters);
        }

        if(req.query && req.query.key) {
            var url = buildUrl(remoteFilters, 'issues.json');
            request({url: url, json: true, agentOptions: {rejectUnauthorized: false}}, callback);
        }
        else {
            res.json({error: 'API key is missing'});
        }
    }

    function setstatus(req, res, remoteFilters) {

      function callback(error, response, data) {
        if(!error && response.statusCode === 200) {
          res.json({data: 'success'});
        }
        else {
          res.json({error: error});
        }
      }

      if(req.body && req.body.key){
        var path = 'issues/'+req.body.id+'.json'
        var url = buildUrl(remoteFilters, path);
        request({
          url: url,
          method: 'PUT',
          agentOptions: {rejectUnauthorized: false},
          //followAllRedirects: true,
          json: {issue:{status_id: req.body.statusId}}
        }, callback);
      }
      else {
        res.json({error: 'API key is missing'});
      }
    }

    function simpleQuery(req, res, path, remoteFilters) {
      function callback(error, response, data) {
        if(!error && response.statusCode === 200) {
          res.json({data: data});
        }
        else {
          res.json({error: error});
        }
      }

      if(req.query && req.query.key) {
          var url = buildUrl(remoteFilters, path);
          request({url: url, json: true, agentOptions: {rejectUnauthorized: false}}, callback);
      }
      else {
          res.json({error: 'API key is missing'});
      }

    }

    //the API to expose
    return {
        config: config,
        query: redmineAllPagesQuery,
        multipleQueries: redmineMultipleIssuesQuery,
        simpleQuery: simpleQuery,
        setstatus: setstatus
    };

})();
