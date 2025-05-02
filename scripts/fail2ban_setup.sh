#!/bin/bash
# fail2ban setup
# One-shot setup for fail2ban with SSH, nginx-badbots, and nginx-attacks jails (Ubuntu only)

set -e

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31mRun this script as root or with sudo!\033[0m"
    exit 1
fi

# Prompt for SSH port with default 22
read -p "Set SSH port [22]: " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

# Install fail2ban
apt update
apt install -y fail2ban

# Stop fail2ban before config
systemctl stop fail2ban || true

# Overwrite jail.local
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
# Ban IP addresses for one year by default
bantime = 31536000
findtime = 86400
maxretry = 3

[badbots]
enabled = true
port = http,https
filter = badbots
logpath = /var/log/nginx/access.log
maxretry = 2
action = iptables-multiport[name=BadBots, port="http,https"]

[nginx-attacks]
enabled = true
port = http,https
filter = nginx-attacks
logpath = /var/log/nginx/access.log
maxretry = 2

[sshd]
enabled = true
port = $SSH_PORT
maxretry = 3
mode = aggressive
EOF

cat > /etc/fail2ban/filter.d/badbots.conf <<EOF
[Definition]

badbotscustom = EmailCollector|WebEMailExtrac|TrackBack/1\.02|sogou music spider|(?:Mozilla/\d+\.\d+ )?Jorgee
badbots = Atomic_Email_Hunter/4\.0|atSpider/1\.0|autoemailspider|bwh3_user_agent|China Local Browse 2\.6|ContactBot/0\.2|ContentSmartz|DataCha0s/2\.0|DBrowse 1\.4b|DBrowse 1\.4d|Demo Bot DOT 16b|Demo Bot Z 16b|DSurf15a 01|DSurf15a 71|DSurf15a 81|DSurf15a VA|EBrowse 1\.4b|Educate Search VxB|EmailSiphon|EmailSpider|EmailWolf 1\.00|ESurf15a 15|ExtractorPro|Franklin Locator 1\.8|FSurf15a 01|Full Web Bot 0416B|Full Web Bot 0516B|Full Web Bot 2816B|Guestbook Auto Submitter|Industry Program 1\.0\.x|ISC Systems iRc Search 2\.1|IUPUI Research Bot v 1\.9a|LARBIN-EXPERIMENTAL \(efp@gmx\.net\)|LetsCrawl\.com/1\.0 \+http\://letscrawl\.com/|Lincoln State Web Browser|LMQueueBot/0\.2|LWP\:\:Simple/5\.803|Mac Finder 1\.0\.xx|MFC Foundation Class Library 4\.0|Microsoft URL Control - 6\.00\.8xxx|Missauga Locate 1\.0\.0|Missigua Locator 1\.9|Missouri College Browse|Mizzu Labs 2\.2|Mo College 1\.9|MVAClient|Mozilla/2\.0 \(compatible; NEWT ActiveX; Win32\)|Mozilla/3\.0 \(compatible; Indy Library\)|Mozilla/3\.0 \(compatible; scan4mail \(advanced version\) http\://www\.peterspages\.net/?scan4mail\)|Mozilla/4\.0 \(compatible; Advanced Email Extractor v2\.xx\)|Mozilla/4\.0 \(compatible; Iplexx Spider/1\.0 http\://www\.iplexx\.at\)|Mozilla/4\.0 \(compatible; MSIE 5\.0; Windows NT; DigExt; DTS Agent|Mozilla/4\.0 efp@gmx\.net|Mozilla/5\.0 \(Version\: xxxx Type\:xx\)|NameOfAgent \(CMS Spider\)|NASA Search 1\.0|Nsauditor/1\.x|PBrowse 1\.4b|PEval 1\.4b|Poirot|Port Huron Labs|Production Bot 0116B|Production Bot 2016B|Production Bot DOT 3016B|Program Shareware 1\.0\.2|PSurf15a 11|PSurf15a 51|PSurf15a VA|psycheclone|RSurf15a 41|RSurf15a 51|RSurf15a 81|searchbot admin@google\.com|ShablastBot 1\.0|snap\.com beta crawler v0|Snapbot/1\.0|Snapbot/1\.0 \(Snap Shots&#44; \+http\://www\.snap\.com\)|sogou develop spider|Sogou Orion spider/3\.0\(\+http\://www\.sogou\.com/docs/help/webmasters\.htm#07\)|sogou spider|Sogou web spider/3\.0\(\+http\://www\.sogou\.com/docs/help/webmasters\.htm#07\)|sohu agent|SSurf15a 11 |TSurf15a 11|Under the Rainbow 2\.2|User-Agent\: Mozilla/4\.0 \(compatible; MSIE 6\.0; Windows NT 5\.1\)|VadixBot|WebVulnCrawl\.unknown/1\.0 libwww-perl/5\.803|Wells Search II|WEP Search 00

failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*"(?:%(badbots)s|%(badbotscustom)s)"$

ignoreregex =
EOF

# Create nginx-attacks filter
cat > /etc/fail2ban/filter.d/nginx-attacks.conf <<EOF
[INCLUDES]
before = common.conf

[Definition]
failregex = ^<HOST> -.*"(GET|POST).*.php.*" 404
            ^<HOST> -.*"(GET|POST).*\.env.*" 404
            ^<HOST> -.*"(GET|POST).*parameters\.yml.*" 404
            ^<HOST> -.*"(GET|POST).*phpunit.*eval-stdin\.php.*" 404
            ^<HOST> -.*"(GET|POST).*/think.*call_user_func_array.*" 404
            ^<HOST> -.*"(GET|POST).*\.git/config.*" 404
            ^<HOST> -.*"(GET|POST).*phpinfo.*" 200
            ^<HOST> -.*"(GET|POST).*/server-status.*" 404
            ^<HOST> -.*"(GET|POST).*/config\.json.*" 404
            ^<HOST> -.*"(GET|POST).*/telescope/.*" 404
            ^<HOST> -.*"(GET|POST).*cgi-bin/.*" 404
            ^<HOST> -.*"(GET|POST).*\.aws/credentials.*" 404
            ^<HOST> -.*"(GET|POST).*\.env\..*" 404
            ^<HOST> -.*"(GET|POST).*\.config\.yaml.*" 404
            ^<HOST> -.*"(GET|POST).*application/.*" 404
            ^<HOST> -.*"(GET|POST).*/favicon\.ico.*" 404
            ^<HOST> -.*"(GET|POST).*/wp-admin.*" 404
            ^<HOST> -.*"(GET|POST).*/wp-login.*" 404
            ^<HOST> -.*"(GET|POST).*\.sql.*" 404
            ^<HOST> -.*"(GET|POST).*/administrator.*" 404
            ^<HOST> -.*"(GET|POST).*/jenkins.*" 404
            ^<HOST> -.*"(GET|POST).*\.htaccess.*" 404
            ^<HOST> -.*"(GET|POST).*/solr/.*" 404
            ^<HOST> -.*"(GET|POST).*/api/swagger.*" 404
            ^<HOST> -.*"(GET|POST).*/api/docs.*" 404

ignoreregex =
EOF

# Enable and start fail2ban
systemctl enable --now fail2ban

# Show status
systemctl status fail2ban --no-pager
fail2ban-client status

echo -e "\n\033[1;32mFail2ban setup complete!\033[0m"
echo "Check jails with: fail2ban-client status"
echo "Check banned IPs: fail2ban-client status sshd | grep Banned"
echo "Check banned IPs: fail2ban-client status nginx-badbots | grep Banned"
echo "Check banned IPs: fail2ban-client status nginx-attacks | grep Banned"
