module.exports = {
  httpPort: 3000
  lhRoot: '/data'
  lhUploads: '/uploads'
  fileZuendstoff:
    'http://infoini.de/redmine/attachments/download/422/zs-ss2015.pdf'
  refreshIntervalCafe: 1000
  refreshIntervalTuer: 1000
  refreshIntervalMensa: 30*60*1000
  tuerHost: 'localhost'
  tuerPort: 51966
  cafeHost: 'iniwlan.beuth-hochschule.de'
  cafePort: 4000
  mensaUrl:
    'http://www.studentenwerk-berlin.de/speiseplan/rss/beuth/woche/kurz/0'
  redmineAuthKey: ''
  ldapServerUrl: 'ldap://localhost:389'
  ldapBindDn: 'cn=root'
  ldapBindCredentials: ''
  ldapSearchBase: ''
  ldapSearchFilter: 'uid={{username}}'
  sessionSecret: '' + Math.random()
  elasticHost: 'elasticsearch:9200'
}
