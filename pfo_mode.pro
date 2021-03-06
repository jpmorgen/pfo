;+
; NAME: pfo_mode
;
; PURPOSE: Keep track of "mode" of a pfo parameter:  fixed, free,
; active, inactive and delete.
;
; CATEGORY: PFO
;
; CALLING SEQUENCE: pfo_mode, parinfo, mode, idx=idx, [/permanent],
; [/cancel_permanent], [query=query]

; DESCRIPTION: This routine allows users to conveniently make
; individual parameters or whole functions fixed, free, active or
; inactive.  Deletion is also supported.

; INPUTS: 
;  parinfo: 	parinfo array
;  mode is a string (case insensitive):

;	fixed: fix the indicated parameters unless they are marked as
;	permanently free

;	free: free the indicated parameters unless they are maked as
;	permanently fixed

;	inactive: mark the parameters as inactive, so they won't
;	be used in the pfo system.  This also affects the .fixed tag,
;	since MPFIT needs to know not to used the parameters in its
;	free parameter count.  .fixed is cached in pfo.ofixed

;	active: re-activate parameters that had been previously
;	inactive, restoring their previous .fixed values

;	delete: mark parameters for deletion.  Use pfo_gc to remove
;	then from the parinfo array.

;	query (or nothing): doesn't set anything (fixed/free
;	status is returned in query keyword)


;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;	idx: the indices of the parameters you want to modify

;       permanent: (fixed/free) keep the parameter(s) "permanently"
;       fixed or free.  This is useful in functions, like pfo_poly
;       that have parameters, such as reference values, which need to
;       be part of the information that the parinfo caries but which
;       are not intended to vary.

;       cancel_permanent: (fixed/free) cancel "permanent" status

;	query: queries status of all non-"permanent" parameters,
;	returns !pfo.fixed (1) if fixed, !pfo.free (0) if free, and
;	!pfo.indeterminate (-1) if there is a mix of fixed and free

;	_EXTRA args are passed on to pfo_ROI_idx to further limit idx

; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS:  
;   Common blocks are ugly.  Consider using package-specific system
;   variables.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:

;; Create a polynomial with a fixed poly_ref parameter
; parinfo = pfo_fcreate(!pfo.poly, poly_order=2, poly_ref=0)
; junk = pfo_funct(/INDICES, parinfo=parinfo, poly_ref=poly_ref_idx)
; pfo_mode, parinfo, idx=poly_ref_idx, 'fixed', /permanent

; pfo_mode


;
; MODIFICATION HISTORY:
;
; $Id: pfo_mode.pro,v 1.5 2011/09/16 13:57:38 jpmorgen Exp $
;
; $Log: pfo_mode.pro,v $
; Revision 1.5  2011/09/16 13:57:38  jpmorgen
; Fixed bug in permanent stuff
;
; Revision 1.4  2011/09/08 20:00:10  jpmorgen
; Fixed bug in /permanent /cancel_permanent
;
; Revision 1.3  2011/09/01 22:28:02  jpmorgen
; Significant improvements to parinfo editing widget, created plotwin
; widget, added pfo_poly function.
;
; Revision 1.2  2011/08/01 18:31:17  jpmorgen
; First reasonably functional version of pfo_obj
;
; Revision 1.1  2011/02/10 22:28:27  jpmorgen
; Initial revision
;
;-
pro pfo_mode, parinfo, mode, idx=idx, permanent=permanent, $
              cancel_permanent=cancel_permanent, query=query, $
              _REF_EXTRA=extra
  init = {pfo_sysvar}
  init = {tok_sysvar}

  ;; Handle pfo_debug level.  CATCH errors if _not_ debugging
  if !pfo.debug le 0 then begin
     ;; Return to the calling routine with our error
     ON_ERROR, !tok.return
     CATCH, err
     if err ne 0 then begin
        CATCH, /CANCEL
        message, /NONAME, !error_state.msg, /CONTINUE
        message, 'USAGE: pfo_mode, mode, [idx=idx], [/permanent], [/cancel_permanent], [query], where mode is a string: ''fixed'', ''free'', ''inactive'', ''active'', ''delete''.  The permanent flags refer to fixed and free, not delete.  To permanently delete parameters, use the ''delete'' mode and then pfo_gc'
     endif
  endif ;; not debugging

  ;; Get our input parinfo and idx straight
  npar = N_elements(parinfo)
  if npar eq 0 then $
    return
  pfo_idx, parinfo, idx
  ;; Narrow with pfo_ROI_idx
  idx = pfo_ROI_idx(parinfo, idx=idx, _EXTRA=extra)

  ;; Handle the /permanent and /cancel_permanent switches
  if keyword_set(permanent) + keyword_set(non_permanent) gt 1 then $
     message, 'ERROR: specify permanent, non_permanent or neither, but not both.'

  ;; Canceling permanent should go first
  if keyword_set(cancel_permanent) then $
     parinfo[idx].pfo.fixed_mode  = !pfo.non_permanent
  
  ;; Get the indices of the parameters that we are going to be allowed
  ;; to change (note this applies only to fixed and free)
  nonperm_idx = where(parinfo[idx].pfo.fixed_mode ne !pfo.permanent, nonperm_count)

  if N_elements(mode) eq 0 then $
    mode = 'query'
  lmode = strlowcase(mode)
  case lmode of
     'delete' : begin
        parinfo[idx].pfo.status = !pfo.delete
        ;; make sure we take these parameters out of MPFIT's free
        ;; parameter calculation
        parinfo[idx].fixed = !pfo.fixed
     end
     'inactive' : begin
        ;; Make sure that multiple calls to 'inactive' don't nuke our
        ;; saved fixed values
        change_idx = where(parinfo[idx].pfo.status ne !pfo.inactive, count)
        if count eq 0 then $
          BREAK
        ;; If we made it here, we have some parameters we need to mark
        ;; inactive.
        ;; unwrap
        change_idx = idx[change_idx]
        parinfo[change_idx].pfo.status = !pfo.inactive
        ;; Save off our fixed value for later use if we ever
        ;; reactivate this parameter
        parinfo[change_idx].pfo.ofixed = parinfo[change_idx].fixed
        ;; Tell MPFIT this parameter is fixed so it doesn't mess
        ;; up the free parameter count
        parinfo[change_idx].fixed = !pfo.fixed
     end
     'active' : begin
        parinfo[idx].pfo.status = !pfo.active
        ;; Resurrect our fixed value.  We can do this as many times as
        ;; we want without harm
        parinfo[idx].fixed = parinfo[idx].pfo.ofixed
     end
     'fixed' : begin
        ;; If we have no parameters we are allowed to tweak, we are done
        if nonperm_count eq 0 then $
          BREAK
        ;; unwrap
        nonperm_idx = idx[nonperm_idx]
        parinfo[nonperm_idx].fixed  = !pfo.fixed
     end
     'free' : begin
        ;; If we have no parameters we are allowed to tweak, we are done
        if nonperm_count eq 0 then $
          BREAK
        ;; unwrap
        nonperm_idx = idx[nonperm_idx]
        parinfo[nonperm_idx].fixed  = !pfo.free
     end
     'query' : 
     else : message, 'ERROR: invalid mode ' + strtrim(mode, 2)

  endcase

  ;; After we have set our mode, make it permanent, if desired
  if keyword_set(permanent) then $
     parinfo[idx].pfo.fixed_mode  = !pfo.permanent

  ;; Raise a warning if someone thinks that /permanent refers to
  ;; something other than fixed or free
  if lmode ne 'fixed' and lmode ne 'free' and (keyword_set(permanent) or keyword_set(permanent)) then $
    message, 'WARNING: permanent or cancel_permanent flag specified with ' + strtrim(mode, 2) + ' These flags only apply to ''fixed'' and ''free'' mode.  See documentation.'

  if arg_present(query) or N_elements(query) ne 0 then begin
     query = !pfo.indeterminate
     if nonperm_count gt 0 then begin
        ;; unwrap
        nonperm_idx = idx[nonperm_idx]
        ;; Check to see if all of the non-permanent fixed values are one
        ;; or the other of free or fixed...
        tfixed = total(parinfo[nonperm_idx].fixed)
        all_same = tfixed eq 0 or tfixed eq nonperm_count
        ;; ...if so, we have our return value
        if all_same then $
          query = parinfo[nonperm_idx[0]].fixed
     endif ;; we have some non-permanent parameters
  endif ;; returning


end
