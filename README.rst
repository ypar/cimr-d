
********************************************************************
cimr-d: client and database for continuously integrated metaresource
********************************************************************

YoSon Park <cimrroot at gmail dot com>


====================
Using data in cimr-d
====================


If you are looking for processed files, you do not need to clone
the cimr-d GitHub repository. All information you need is
provided in the `catalog.txt`_, which you can download by clicking
the link and viewing raw file or by typing the following in a terminal::

    wget https://raw.githubusercontent.com/greenelab/cimr-d/master/catalog.txt


Cloning the full repository will not download all data stored in the
cimr-d AWS S3 bucket. So you may safely clone the repository to keep a
local copy of the catalog::

    git clone git@github.com:greenelab/cimr-d.git


Frequent pulling is recommended as cimr-d may be updated with new or
improved information.



While data processing can be streamlined, any data used in research
studies should be carefully reviewed in the context of its original
publication. To make this as convenient as possible, we provide
doi of each citable publication in the `catalog.txt`_, `.bib` file to be
used in the `bibtex directory`_, and the `full reference`_.



.. _catalog.txt: https://raw.githubusercontent.com/greenelab/cimr-d/master/catalog.txt
.. _bibtex directory: https://github.com/greenelab/cimr-d/tree/master/doc/bibtex
.. _full reference: https://github.com/greenelab/cimr-d/blob/master/doc/references.md




=====================================
Regarding Licence and Usage of cimr-d
=====================================

All citations and references for data stored in cimr-d are added to
`cimr-d references`_. Recommended acknowledgement and citation
information from the original data providers are available as a
guideline.



All data deposited here have been either

* contributed by researchers who own the copyright or license to the data, or

* reprocessed and deposited from a public source.



We take every caution to make sure data stored and used via cimr-d
suite are approved for public sharing and reuse for research
purposes. If any data currently available here require more
strict licenses, different citation/acknowledgement rules,
or any special usage guidelines, contact us and we will take
appropriate actions.

For cimr usage independent of cimr-d, see the `cimr manual`_.
For any PR including new data, we strongly recommend including
appropriate citations, metadata and other relevant information
regarding the data to be added to `cimr citations`_.



.. _cimr-d references: https://github.com/greenelab/cimr-d/blob/master/doc/references.md
.. _cimr manual: https://cimr.readthedocs.io
.. _cimr citations: https://github.com/greenelab/cimr/blob/master/doc/source/citations.rst



=================
Contributing data
=================

cimr-d is built to be a community resource and benefits greatly
by contributors of all levels, from research data to development.
For details regarding how to contribute data to cimr-d, please see
the `cimr-d contributions`_ doc.


Briefly,::

    1. make a GitHub account
    2. fork this repository
    3. clone the forked repository
    4. copy your yaml file(s) into the "submitted" directory
    5. use git commands to add, commit and push your changes to the forked repository


.. _cimr-d contributions: https://github.com/greenelab/cimr-d/blob/master/doc/contributing.md



=================
cimr-d references
=================


* If you find cimr and cimr-d useful, please cite:

  * Park Y., Hu D. & Greene C., (2019). "Deciphering complex trait
    genetics using a continuously integrated meta-resource, cimr-d",
    Manuscript in Preparation

  * Park Y. (2019), cimr, https://github.com/greenelab/cimr


