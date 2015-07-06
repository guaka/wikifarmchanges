

@changes = []
@changesObj = {}
@statsObj = {}


@fetchChanges = (wiki) ->
  # Simplest: entity is name and everything is standard
  if typeof wiki is 'string'
    wiki = { name: wiki }

  # Standard unless it's not
  wiki.apiPath = 'w/' unless wiki.apiPath?
  wiki.articlePath = 'en' unless wiki.articlePath?
  host = if wiki.host? then wiki.host else wiki.name
  host += '/'


  # Not so DRY but hey, it works!
  $.getJSON('http://' + host + wiki.apiPath + '/api.php?callback=?',
    format: "json"
    action: "query"
    meta: 'siteinfo'
    siprop: 'statistics'
    ).done (data) ->
      stats = data.query.statistics

      statsObj[host + wiki.articlePath] = stats

      Session.set 'changed', Meteor.uuid()

  $.getJSON('http://' + host + wiki.apiPath + '/api.php?callback=?',
    format: "json"
    action: "query"
    list: 'recentchanges'
    rcprop: 'user|title|ids|comment|sizes|timestamp|loginfo'
    ).done (data) ->
      rc = data.query.recentchanges

      changesObj[wiki.name] = _.map rc, (x) ->
        x.link = 'http://' + host + wiki.articlePath + '/' + x.title
        x.timestamp = moment(x.timestamp).fromNow()
        x.comment = if x.logtype is 'delete' then '' else x.comment[..30]
        x

      Session.set 'changed', Meteor.uuid()


@updateChanges = ->
  Session.set 'updated', moment().format("H:mm:ss")
  console.log _.map wikis, (w) -> w.name
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



Template.changes.helpers
  title: -> if siteTitle? then siteTitle else 'Wikifarmchanges'
  updated: -> Session.get 'updated'
  changes: ->
    Session.get 'changed'
    changes = _.map (_.pairs changesObj), (p) ->
      name: p[0]
      rc: p[1]
      numArticles: statsObj?[p[0]]?.articles
    _.sortBy changes, (x) -> x.name



Template.changes.events
  'click #refresh': ->
    updateChanges()
