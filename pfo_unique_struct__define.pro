;+
; NAME: pfo_unique_struct__define
;
; PURPOSE: Create a tag that has a unique identifier for each array element
;
; CATEGORY: PFO arrays
;
; CALLING SEQUENCE:

; DESCRIPTION: This structure allows a simple numeric label to be
; attached to each parinfo record.  It is useful for seeing if the
; order of parameters change when the parinfo is modified (see
; pfo_parinfo_cw_obj::prepopfresh_check)

; NOTE: the uniqueID is not meant to be persistent

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
;
; MODIFICATION HISTORY:
;
; $Id: pfo_unique_struct__define.pro,v 1.1 2011/09/01 22:15:05 jpmorgen Exp $
;
; $Log: pfo_unique_struct__define.pro,v $
; Revision 1.1  2011/09/01 22:15:05  jpmorgen
; Initial revision
;
;-

pro pfo_unique_struct__update, $
   parinfo

  ;; We should be called by pfo_struct_call_procedure, so we
  ;; wouldn't be here unless everything was defined.
  uniqueID = parinfo.pfo_unique.uniqueID

  u_idx = pfo_uniq(uniqueID, sort(uniqueID), reverse_indices=r_idx, N_uniq=N_uniq)
  ;; If we have one uniqueID for each parinfo, our work is done
  if N_uniq eq N_elements(parinfo) then $
     return

  ;; If we made it here, we have to figure out what to do with
  ;; non-unique elements in the parinfo.  We don't really know
  ;; which uniqueIDs were the "original" ones, but usually we use
  ;; pfo_array_append when making changes to the parinfo, so the later
  ;; ones are the interlopers

  ;; Cycle through each uniq uniqueID
  for iu=0,N_uniq-1 do begin
     ;; Cycle through the non-uniqueIDs in this list.  The first
     ;; occurrence of uniqueID is, by definition, unique, so only
     ;; change subsequent instances.  The loop is skipped if this the
     ;; uniqueID is unique.  This also prefers the first-listed uniqueID
     non_uniq_idx = r_idx[r_idx[iu]:r_idx[iu+1]-1]
     for inu=1,r_idx[iu+1] - r_idx[iu] - 1 do begin
        mu = max(uniqueID)
        mu1 = mu + 1
        ;; Check to see if we have wrapped our integer type
        if mu1 lt mu then begin
           message, 'WARNING: uniqueID integer wrap detected.  Using the simple memory management techniqe of packing the uniqueID array.  UniqueIDs are likely to change as a result.  This might cause a one-time hiccup in the calling code'
           uniqueID = indgen(N_elements(uniqueID), type=size(/type, uniqueID))
           parinfo.pfo_unique.uniqueID = uniqueID
           return
        endif ;; integer wrap

        ;; If we made it here, we can find a uniqueID just by
        ;; incrementing the current max uniqueID
        uniqueID[non_uniq_idx[inu]] = mu1

     endfor ;; each non-unique group
  endfor ;; Each uniqueID

  ;; Put uniqueID back into parinfo
  parinfo.pfo_unique.uniqueID = uniqueID

end

pro pfo_unique_struct__get_tag, $
   parinfo, $
   idx=idx, $
   taglist_series= taglist_series, $ ;; See pfo_setget_tag
   strict= strict, $ ;; See pfo_setget_tag
   _REF_EXTRA   	= extra, $
   uniqueID=uniqueID

  if !pfo.debug le 0 then begin
     CATCH, err
     if err ne 0 then begin
        CATCH, /CANCEL
        message, /NONAME, !error_state.msg, /CONTINUE
        message, 'ERROR: caught the above error.  Returning with what I have done so far ', /CONTINUE
        return
     endif
  endif ;; not debugging

  ;; Make sure idx exists
  pfo_idx, parinfo, idx

  ;; Put our struct into a tag, if necessary
  pfo_struct_tagify, parinfo, tagified=tagified

  ;; If we made it here, we are good to copy our tags into the
  ;; keywords

  if arg_present(uniqueID    ) or N_elements(uniqueID    ) ne 0 then uniqueID     = parinfo[idx].pfo_unique.uniqueID 	  

  ;; Put our tag back on the top-level, if necessary
  pfo_struct_tagify, parinfo, tagified=tagified

  ;; Pass on keywords processed in series to the next top-level tag
  ;; listed in taglist_series.  
  pfo_struct_setget_tag, parinfo, idx=idx, /next, /get, $
                      taglist_series=taglist_series, $
                      strict=strict, $
                      _EXTRA=extra

end

pro pfo_unique_struct__set_tag, $
   parinfo, $
   idx=idx, $
   taglist_series= taglist_series, $ ;; See pfo_setget_tag
   strict= strict, $ ;; See pfo_setget_tag
   _REF_EXTRA   	= extra, $
   uniqueID=uniqueID

  if !pfo.debug le 0 then begin
     CATCH, err
     if err ne 0 then begin
        CATCH, /CANCEL
        message, /NONAME, !error_state.msg, /CONTINUE
        message, 'ERROR: caught the above error.  Returning with what I have done so far ', /CONTINUE
        return
     endif
  endif ;; not debugging

  ;; Make sure idx exists
  pfo_idx, parinfo, idx

  ;; Put our struct into a tag, if necessary
  pfo_struct_tagify, parinfo, tagified=tagified

  ;; If we made it here, we are good to copy our keywords into the
  ;; tags

  if N_elements(uniqueID    ) ne 0 then parinfo[idx].pfo_unique.uniqueID 	  = uniqueID

  ;; Put our tag back on the top-level, if necessary
  pfo_struct_tagify, parinfo, tagified=tagified

  ;; Pass on keywords processed in series to the next top-level tag
  ;; listed in taglist_series.  
  pfo_struct_setget_tag, parinfo, idx=idx, /next, /set, $
                      taglist_series=taglist_series, $
                      strict=strict, $
                      _EXTRA=extra

end 

function pfo_unique_struct__init, $
   descr=descr, $
   _REF_EXTRA=extra

  ;; Create our struct initialized with generic IDL null values.  We
  ;; could also have called:
  ;; pfo_struct = create_struct(name='pfo_struct')
  pfo_unique_struct = {pfo_unique_struct}

  ;; 0 is a fine init for the uniqueID, so we don't need to do
  ;; any more default initialization

  ;; Create our description
  descr = $
    {README	: 'Provides a tag that keeps track of a unique identifier for each element in the parinfo array', $
     uniqueID	: 'Unique identified assigned by pfo_unique_struct__update "method"'}

  ;; The last thing we do is pass on any other keywords to our
  ;; __set_tag "method."  Do this with _STRICT_EXTRA to make sure that
  ;; no bogus keywords are passed.  Be careful with debugging and make
  ;; sure user gets the best effort case when we are trying to ignore
  ;; the error.
  if !pfo.debug le 0 then begin
     CATCH, err
     if err ne 0 then begin
        message, /NONAME, !error_state.msg, /CONTINUE
        message, /INFORMATIONAL, 'WARNING: the above error was produced.  Use pfo_debug to help fix error, pfo_quiet, to suppress reporting (not recommended).' 
        return, pfo_struct
     endif ;; CATCH
  endif ;; debugging
  pfo_unique_struct__set_tag, pfo_unique_struct, _STRICT_EXTRA=extra

  return, pfo_unique_struct

end


pro pfo_unique_struct__define

  ;; Read in system variables for all routines in this file.
  init = {pfo_sysvar}
  init = {tok_sysvar}

  ;; Define our named structure
  pfo_unique_struct = $
     {pfo_unique_struct, $
      uniqueID	:	0L $
      }
end