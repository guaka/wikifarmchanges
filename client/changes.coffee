

@changes = []
@changesObj = {}
@statsObj = {}
@rc_urls = {}

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
      statsObj[wiki.name] = stats
      Session.set 'changed', Meteor.uuid()

  $.getJSON('http://' + host + wiki.apiPath + '/api.php?callback=?',
    format: "json"
    action: "query"
    list: 'recentchanges'
    rcprop: 'user|title|ids|comment|sizes|timestamp|loginfo'
    ).done (data) ->
      rc = data.query.recentchanges

      changesObj[wiki.name] = _.map rc, (change) ->
        # change.link = 'http://' + host + wiki.articlePath + '/=' + change.title
        change.link = 'http://' + host + '/' + wiki.articlePath + '/index.php?title=' + change.title
        change.timestamp = moment(change.timestamp).fromNow()
        change.comment = if change.logtype is 'delete' then '' else change.comment[..30]
        change

      Session.set 'changed', Meteor.uuid()


@updateChanges = ->
  Session.set 'updated', moment().format("H:mm:ss")
  # console.log _.map wikis, (w) -> w.name
  for w in wikis
    fetchChanges w


Meteor.startup ->
  for w in wikis
    rc_urls[w.name] = 'http://' + w.host + '/' + w.articlePath + '/index.php?title=Special:Recentchanges'
    
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
    changes = _.map (_.pairs changesObj), (page) ->
        rc_url: rc_urls[page[0]]
        name: page[0]
        rc: page[1]
        numArticles: statsObj?[page[0]]?.articles
    _.sortBy changes, (change) -> change.name



Template.changes.events
  'click #refresh': ->
    updateChanges()
