README
======

This toolset is intended to analyze Mahara-based learning e-portfolios. The idea is to allow teachers to get an overview on a group's set of portfolios using web-scraping, with a number of statistics.

As a matter of fact, major aspects of this toolset concern the authorized access to such Mahara portofolios, which in practice may differ from organization to organization.
Also, the web-scraping approach may have to be adapted based on the Mahara style sheets applied in one's organization.
So expect to have to adapt or rewrite major parts of the code.

The current implementation accesses Mahara via a moodle account (since in our organization the direct access of Mahara is disabled. Mahara access is  using web-scraping

The analyzer is to be started in a shell with portfolio_anaylzer as the main file. You will be asked for the URL of the Moodle main page and the account credentials to access your individual Mahara dashboard. There, it will extract all your groups and allow you to select one of them. For this group, all members will be extracted (and the administrators filtered). So you get a list with the names of the members and the links to the corresponding Mahara pages. That's it so far!

Gems
====

At present, the following gems are being used:
* highline (>= 2.0.0.pre.develop.4)
* fastimage (>= 1.8.1)
* nokogiri (>= 1.6.7)
* mechanize (>= 2.7.4)
* rsolr (>= 1.1.1.pre1, 1.0.13)
* rsolr-ext (>= 1.0.3)
* rsolr-json (>= 0.0.1)
* rsolr-nokogiri (>= 0.0.0)
* sanitize (>= 4.0.1)
* words_counted (>= 1.0.2)
