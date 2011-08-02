;+
; NAME: pfo_scint_fdefine
;
; PURPOSE: define, initialize and work with the PFO_scint function
;
; CATEGORY: PFO functions
;
; CALLING SEQUENCE: All functionality is best accessed from
; higher-level PFO routines, like pfo_funct and pfo_fidx
;
; DESCRIPTION:

; This code is organized into "methods," such as __fdefine, __finit,
; __calc and __indices.  Note that some of the code is
; interdependent (e.g. __calc calls __indices, __fdefine is the
; first routine called), so the order these routines are listed in the
; file is important.  Brief documentation on each "method" is provided
; in the code.  The parameter/keyword lists are also annotated.

;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS:  
;   See pfo_finfo.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
; $Id: pfo_scint__fdefine.pro,v 1.1 2011/08/01 19:18:16 jpmorgen Exp $
;
; $Log: pfo_scint__fdefine.pro,v $
; Revision 1.1  2011/08/01 19:18:16  jpmorgen
; Initial revision
;
;-

;; The __indices "method" maps keyword names to the indices of those
;; parameters.  It is intended to be called ONLY for one instance of
;; the function at a time.  The pfo_funct /INDICES "method" can be
;; used to process multiple function instances.
function pfo_scint__indices, $
   parinfo=parinfo, $    ;; parinfo containing scint function(s)
   idx=idx, $	;; idx into parinfo over which to search for scint function(s)
   E0=E0, $		;; peak energy
   area=area, $		;; area
   W0=W0, $		;; Gaussian sigma=sqrt(W0 + E(0)*W1)
   W1=W1, $
   f_step=f_step, $	;; amplitude of the smothed step
   value=value, $   ;; catch value to make sure no conflict with other keywords
   ftype=ftype, $ ;; catch ftype to make sure no conflict in pfo_struct_setget_tag
   peak=peak, $		;; generic for E0
   width=width, $	;; generic for all width-determining parameters
   terminate_idx=terminate_idx, $ ;; insert !tok.nowhere after 
   pfo_obj=pfo_obj, $ ;; pfo_obj for pfo_finfo system, if not defined, PFO COMMON block is used
   _REF_EXTRA=extra	;; _REF_EXTRA passed to pfo_struct_setget_tag

  init = {tok_sysvar}

  ;; Do basic idx error checking and collect our function indices
  idx = pfo_fidx(parinfo, 'pfo_scint', idx=idx, pfo_obj=pfo_obj, $
                 npar=npar, nfunct=nfunct)
  if nfunct ne 1 then $
    message, 'ERROR: ' + strtrim(nfunct, 2) + ' instances of function found, I can only work with one.  Use pfo_parinfo_parse and/or pfo_fidx to help process multiple instances of a function.'

  ;; Get the fractional part of ftype, which determines which
  ;; parameter we are.  Multiply by 10 and round, to prevent precision errors
  ffrac = round(10*pfo_frac(parinfo[idx].pfo.ftype))

  ;; Translate fractional ftype into disambiguated keywords, raising
  ;; errors if we don't get what we expect.
  E0_local = where(ffrac eq 1, count)
  if count ne 1 then $
    message, 'ERROR: bad E0'
  ;; unwrap and make into a scaler
  E0_local = idx[E0_local[0]]

  area_local = where(ffrac eq 2, count)
  if count ne 1 then $
    message, 'ERROR: bad area'
  ;; unwrap and make into a scaler
  area_local = idx[area_local[0]]

  W0_local = where(ffrac eq 3, count)
  if count ne 1 then $
    message, 'ERROR: bad W0'
  ;; unwrap and make into a scaler
  W0_local = idx[W0_local[0]]

  W1_local = where(ffrac eq 4, count)
  if count ne 1 then $
    message, 'ERROR: bad W1'
  ;; unwrap and make into a scaler
  W1_local = idx[W1_local[0]]

  f_step_local = where(ffrac eq 5, count)
  if count ne 1 then $
    message, 'ERROR: bad f_step'
  ;; unwrap and make into a scaler
  f_step_local = idx[f_step_local[0]]

  ;; If we made it here, everything should be in order

  ;; Add our terminate_idx markers, if desired
  if keyword_set(terminate_idx) then begin
     pfo_array_append, E0_local, !tok.nowhere
     pfo_array_append, area_local, !tok.nowhere
     pfo_array_append, W0_local, !tok.nowhere
     pfo_array_append, W1_local, !tok.nowhere
     pfo_array_append, f_step_local, !tok.nowhere
  endif ;; terminators

  ;; Append our indices onto the running arrays, if present
  if N_elements(E0) gt 0 or arg_present(E0) then $
    pfo_array_append, E0, E0_local
  if N_elements(area) gt 0 or arg_present(area) then $
    pfo_array_append, area, area_local
  if N_elements(W0) gt 0 or arg_present(W0) then $
    pfo_array_append, W0, W0_local
  if N_elements(W1) gt 0 or arg_present(W1) then $
    pfo_array_append, W1, W1_local
  if N_elements(f_step) gt 0 or arg_present(f_step) then $
    pfo_array_append, f_step, f_step_local

  ;; Copy disambiguated keywords into others, if desired
  if N_elements(peak) gt 0 or arg_present(peak) then $
    pfo_array_append, peak, E0_local
  ;; Width is a little different, since we have two parameters that
  ;; represent it.
  if N_elements(width) gt 0 or arg_present(width) then $
    pfo_array_append, width, [W0, W1]

  ;; Return indices sorted in order of ffrac
  retval = idx[sort(ffrac)] 
  if keyword_set(terminate_idx) then $
    pfo_array_append, retval, !pfo.nowhere
  return, retval

end

;; The __calc "method" returns the calculated value of the
;; function
function pfo_scint__calc, $
  Xin, $ 	;; Input X axis in natural units 
  params, $ 	;; parameters (entire array)
  parinfo=parinfo, $ ;; parinfo array (whole array)
  idx=idx, $    ;; idx into parinfo over which to search for function
  Xaxis=Xaxis, $;; transformed from Xin by pfo_funct, in case ROI boundary is cast in terms of "real" units.  Passing it this way saves recalculation in this routine
  count=count, $ ;; number of xaxis points found in ROI
  pfo_obj=pfo_obj, $ ;; pfo_obj for pfo_finfo system, if not defined, PFO COMMON block is used
  _REF_EXTRA=extra ;; passed to pfo_Xaxis

  ;; Use shared routines to do basic error checking.  These error
  ;; messages are pretty verbose.

  ;; Common error checking and initialization code
  pfo_calc_check, Xin, params, fname='pfo_scint', parinfo=parinfo, idx=idx, pfo_obj=pfo_obj

  ;; If we made it here, our inputs should be in reasonably good shape
  ;; --> We xassume that we have been called from pfo_parinfo_parse so
  ;; that our idx are sorted in ftype order
  E0    = params[idx[0]]
  area  = params[idx[1]]
  width = params[idx[2:3]]
  f_step= params[idx[4]]

  ;; For now, use the code in grand, written for a BGO detector, which
  ;; is a scintillator, to do the calculation.
  return, gnd_bgo(Xin, E0, area, width, f_step, _EXTRA=extra)
  
end

;; Create the parinfo strand for this function and initialize it
function pfo_scint__init, $
   E0=E0, $		;; peak energy
   area=area, $		;; area
   W0=W0, $		;; Gaussian sigma=sqrt(W0 + E(0)*W1)
   W1=W1, $
   f_step=f_step, $	;; amplitude of the smothed step
   value=value, $   ;; catch value to make sure no conflict with other keywords
   ftype=ftype, $ ;; catch ftype to make sure no conflict in pfo_struct_setget_tag
   pfo_obj=pfo_obj, $	;; pfo_obj for parinfo_template
   peak=peak, $		;; generic for E0
   width=width, $	;; generic for all width-determining parameters
   _REF_EXTRA=extra	;; _REF_EXTRA passed to pfo_struct_setget_tag

  init = {pfo_sysvar}
  init = {tok_sysvar}
  if !pfo.debug le 0 then begin
     ;; Return to the calling routine with our error
     ON_ERROR, !tok.return
     CATCH, err
     if err ne 0 then begin
        CATCH, /CANCEL
        message, /NONAME, !error_state.msg, /CONTINUE
        message, 'USAGE: pfo_scint__init [, pfo_obj=pfo_obj][, E0=E0][, W0=W0][W1=W1][, f_step=f_step][, keywords to convert to tag assignments]'
     endif
  endif ;; not debugging

  ;; Catch improper use of value and ftype keywords
  if N_elements(value) + N_elements(ftype) ne 0 then $
     message, 'ERROR: value and ftype are set internaly: they are therefore invalid keywords'

  ;; Get critical information about this function from pfo_finfo
  pfo_finfo, fname='pfo_scint', fnum=fnum, fnpars=fnpars, pfo_obj=pfo_obj

  ;; Create our parinfo strand for this function, making sure to
  ;; include any substructure we need with required tags.  Start with
  ;; one parinfo element.
  parinfo = pfo_parinfo_template(pfo_obj=pfo_obj, $
                                 required_tags=['pfo'])
  ;; ... replicate it by fnpars
  parinfo = replicate(temporary(parinfo), fnpars)

  ;; Set attributes/defaults that are unique to this function.  Note
  ;; that some attributes are already defined in pfo_struct__init
  ;; (found in pfo_struct__define.pro)
  
  ;; PARNAME
  ;; Don't put function name in parname, since it can be
  ;; reconstructed from pfo.ftype.  Packages built on top of pfo
  ;; may want to set !pfo.longnames = 0 to use these short names
  parinfo.parname = ['E0', $
                     'A', $
                     'W0', $
                     'W1', $
                     'fs']
  if !pfo.longnames ne 0 then $
    parinfo.parname = ['Peak energy', $
                       'Area', $
                       'W0', $
                       'W1', $
                       'f step']


  ;; FTYPE -- fractional part (ffrac).  A different decimal value can
  ;;          be associated with each parameter of the function.  For
  ;;          complicated associations, create a new tag with the
  ;;          pfo_struct system (e.g. pfo_ROI_struct__define.pro)
  parinfo.pfo.ftype = [0.1, $ ;; E0
                       0.2, $ ;; area
                       0.3, $ ;; W0
                       0.4, $ ;; W1
                       0.5]   ;; f_step
  ;; FTYPE -- integer part (fnum).  Dynamically assigned by fdefine
  parinfo.pfo.ftype += fnum

  ;; VALUE.  Default to E0=0, area=0, W0=0, W1=1, f_step=0
  if N_elements(E0) + N_elements(peak) gt 1 then $
     message, 'ERROR: specify either E0 or peak'
  if N_elements(peak) ne 0 then $
     E0 = peak
  if N_elements(E0) eq 0 then $
     E0 = 0
  if N_elements(area) eq 0 then $
     area = 0
  if N_elements(W0) + N_elements(width) gt 1 then $
     message, 'ERROR: specify either W0 or width'
  if N_elements(W1) + N_elements(width) gt 1 then $
     message, 'ERROR: specify either W1 or width'
  ;; Convert width to W0 & W1
  if N_elements(width) gt 0 then begin
     W0 = 0 & W1 = 1
     if N_elements(width) eq 1 then $
        W1 = width
     if N_elements(width) eq 2 then begin
        W0 = width[0]
        W1 = width[1]
     endif
     if N_elements(width) gt 2 then $
        message, 'ERROR: width can have at most 2 elements.  It has:' + strtrim(N_elements(width), 2)
  endif ;; converting width to W0 & W1
  if N_elements(W0) eq 0 then $
     W0 = 0
  if N_elements(W1) eq 0 then $
     W1 = 1
  if N_elements(f_step) eq 0 then $
     f_step = 0

  parinfo[0].value = E0
  parinfo[1].value = area
  parinfo[2].value = W0
  parinfo[3].value = W1
  parinfo[4].value = f_step

  ;; LIMITS, LIMITED
  ;; Keep all parameters positive
  parinfo.limits = [0,0]
  parinfo.limited = [1,0]
  ;; --> I suppose W0 could be negative, but assume no for now

  ;; Convert keywords on the command line to tag assignments in the
  ;; parinfo.  This is a little risky, since we might have duplicate
  ;; tags in the different sub-structures (e.g. status is a popular
  ;; one) and, depending on what order the substructures were added
  ;; with required_tags, the behavior might vary.  It is always safer
  ;; to make assignments in your calling code explicitly with the tags
  ;; in the returned parinfo.  Note, we pass all of the _EXTRA to
  ;; pfo_struct_setget_tag, so the calling routine gets to choose
  ;; parallel or series, strict, etc.
  pfo_struct_setget_tag, /set, parinfo, _EXTRA=extra

  return, parinfo

end

;; Map function name to function number and number of parameters in
;; the PFO system
pro pfo_scint__fdefine, pfo_obj=pfo_obj

  pfo_fdefine, pfo_obj=pfo_obj, fname='pfo_scint', fnpars=5, $
               fdescr='pfo_scint was developed as a generic scintillator function.  It is basically a Gaussian plus a smoothed step.  A normal Gaussian has just threre parameters, peak energy (E0), area, and sigma.  In pfo_scint, sigma=sqrt(W0 + E(0)*W1), which allows a physical description of the resolution function of the detector, provided that parameters from multiple lines are properly linked together.  The smoothed step is implemented using the erf function and is basically as wide as sigma, and centered so that the 1/e slope point is E0.  Thus, pfo_scint has 5 parameters, E0, area, W0, W1, and f_step.' 
    
end