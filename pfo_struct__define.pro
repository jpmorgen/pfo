; +
; $Id: pfo_struct__define.pro,v 1.1 2003/12/18 23:58:07 jpmorgen Exp $

; pfo_struct__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; This is a modular part of pfo_parinfo__define.

;; Tag 	Value	Meaning
;; status 0	Indicates to all PFO packages that this parameter not
;; 		used (i.e. set status=0 to have just PFO skip this
;; 		parameter)
;;	  1	parameter in use
;;	 -1	parameter marked for deletion
;;	 1-n	u 
;; ID 	 0-n	Parameter (or function) ID, for use by calling
;; 		routine.  Ideally, the calling routine should append
;; 		its own well-documented structure onto the pfo_parinfo
;; 		structure that provides multiple handles for grabbing 
;; 		groups of parameters.  If the task is simple, however,
;; 		pfo.ID can be used.  In pfo_funct, this is the LAST
;; 		identifier used to differentiate between parameter
;; 		sets that are otherwise equivalent.
;; fseq	 0-n	indicates order in which groups of parameters should
;; 		be handled.  Individual packages may need more a
;; 		sophisticated handling of this
;; inaxis 	What set of points should be used as the input axis to
;; 		this function
;;	  0	independent of axis
;;	  1	input X-axis (usually pixels, e.g. for dispersion
;;	  	relation (outaxis=1) or pixel dependent detector
;;	  	effects (outaxis=2)
;;	  2	transformed X-axis (e.g. for Voigts
;;		parameterized in wavelength)
;;	  3	Y-axis (no clue why this would be used)
;; outaxis 	Where do the results go?
;;	   0	output of function does not operate on any axis
;;	   1	NOT ALLOWED -- input X-axis is always preserved
;;	   2	transformed X-axis
;;	   3	Y-axis (no clue why this would be used)
;; fop		How are the function results combined with the
;; 		existing values on that axis?
;;	  0	Does not output to an axis
;;	  1	Additive function (e.g. Voigt line profile)
;;	  2	Multiplicative function (e.g. instrument sensitivity polynomial)
;;	  3	Replacement (e.g. dispersion relation)
;; ftype  0	this parameter is not handled by a PFO function
;;	  1	segmented polynomial (see below)
;;	  2	delta fn
;;		  2.1 = related to line center
;;		  2.2 = related to area
;; 	  3	Gaussian
;;		  3.1 = related to line center
;;		  3.2 = related to area
;;		  3.3 = related to width
;; 	  4	Voigt
;;		  4.1 = related to line center
;;		  4.2 = related to area
;;		  4.3 = related to Gaussian width
;;		  4.4 = related to Lorentzian width
;;	  Add to this list.  
;;

;; Segmented polynomial scheme
;;
;; This is an attempt at a generic definition for a polynomial
;; function made up of segments.  The first segment starts at the Xin
;; value labeled with ftype=1.0 (if an ftype=1.0 parameter is not
;; specified, the first segment is assumed to start at the first value
;; on the left side of the X-axis).  Segments are assumed to proceed
;; to the right.  The polynomial coefficients are labeled 1.x1-1.x999,
;; where x >= 1.  The boundary between segment x and (x+1) is
;; labeled 1.0x.  If you need more than 9 segments, make another
;; ftype.  1.0, if specified, indicates the start of the X-axis
;; 1.01-1.09 = 1st through 9th reference values (e.g. for dispersion,
;; 1.01=reference pixel for zero point of wavelength axis; for
;; sensitivity function, first break point) 1.10-1.1999 = 0-999th
;; order polynomial coefficient of first polynomial 1.20-1.2999 =
;; 0-999th order polynomial coefficient of second polynomial
;; 1.30-1.n999 = etc.


pro pfo_struct__define
  pfo_struct $
    = {pfo_struct, $
       status	: 0, $
       ID	: 0, $
       fseq	: 0, $
       inaxis	: 0, $
       outaxis	: 0, $
       fop	: 0, $
       ftype 	: 0.,$
       format	: '',$
       eformat	: '' $
      } 
end