

# global for debugging
@changes = []
changesObj = {}

@fetchChanges = (wiki) ->
  apiPath = '/w'
  if typeof wiki is 'string'
    name = wiki
  else
    apiPath = wiki.apiPath
    name = wiki.name

  $.getJSON('http://' + name + apiPath + '/api.php?callback=?',
    format: "json"
    action: "query"
    list: 'recentchanges'
    rcprop: 'user|title|ids|comment|sizes|timestamp|loginfo'
    ).done (data) ->
      rc = data.query.recentchanges

      changesObj[name] = _.map rc, (x) ->
        x.link = 'http://' + name + '/en/' + x.title
        x.timestamp = moment(x.timestamp).fromNow()
        x.comment = if x.logtype is 'delete' then '' else x.comment[..30]
        x

      Session.set 'changed', Meteor.uuid()


@updateChanges = ->
  Session.set 'updated', moment().format("H:mm:ss")
  for w in wikis
    fetchChanges w


Meteor.startup ->
  updateChanges()
  randomInterval()


# http://stackoverflow.com/questions/6962658/randomize-setinterval-how-to-rewrite-same-random-after-random-interval
randomInterval = ->
  rand = 1000 * (Math.round(Math.random() * 60) + 60)
  setTimeout (->
    updateChanges()
    randomInterval()
  ), rand



Template.changes.updated = ->
  Session.get 'updated'

Template.changes.changes = ->
  Session.get 'changed'
  changes = _.map (_.pairs changesObj), (p) ->
    name: p[0]
    rc: p[1]
  _.sortBy changes, (x) -> x.name


Template.changes.events
  'click #refresh': ->
    updateChanges()