Tue Mar  3 17:15:47 2015  jpmorgen@snipe

README

This file serves as the general introduction and roadmap to the
documentation of the Parameter Function Objection (PFO) system.

PFO was originally developed in 2003 with the support of a National
Research Fellowship to Dr. Jeffrey P. Morgenthaler.  The original
version of PFO was developed in the Interactive Data Language (IDL),
version 5.3, a product, at the time, of Research Systems Incorporated
(RSI).  IDL was owned by ITT for a few years and, as of late 2011, is
currently owned by Exelis Visual Information Solutions.  A compatible,
freely distributed IDL compiler, GDL, is being developed under the GNU
Public License.  PFO has yet to be tested with GDL, but works with IDL
versions 5, 6, 7, and 8.

PFO was upgraded to add object-oriented and a IDL widget GUI in 2011
with the support of the Gamma Ray and Neutron Detector (GRaND) project
on NASA's Dawn spacecraft.  At this point IDL version 5 suport was
dropped.

DOCUMENTATION ROADMAP:

README.pfo: general overview of the PFO system.  Start here.

README.pfo_fit: an introduction to the GUI front-end of PFO.

README.pfo_obj: an introduction to the object-oriented interface of
PFO

README.pfo_CZT: an log of how the PFO function pfo_CZT was created
using another function, pfo_scint, as a template.  VERY USEFUL if you
want to create your own functions in PFO.

README.names: a document summarizing the naming conventions used in
the PFO system.  VERY USEFUL if you are going to be creating functions
and augmenting the parinfo structure.
