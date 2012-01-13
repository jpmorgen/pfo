;+
; NAME: pfo_xaxis_idx
;
; PURPOSE: Returns the indices in the parinfo of the function(s) used
; to establish the internal Xaxis
;
; CATEGORY: PFO
;
; CALLING SEQUENCE: Xaxis_idx = pfo_Xaxis_idx(parinfo, idx=idx)
;
; DESCRIPTION:
;
; INPUTS: parinfo: parinfo array
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS: 

;   idx: optional indices into parinfo over which to restrict search

;   count: number of idx found

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
; $Id: pfo_xaxis_idx.pro,v 1.1 2012/01/13 18:48:54 jpmorgen Exp $
;
; $Log: pfo_xaxis_idx.pro,v $
; Revision 1.1  2012/01/13 18:48:54  jpmorgen
; Initial revision
;
;-
function pfo_Xaxis_idx, $
   parinfo, $
   idx=idx, $
   count=count
  
  init = {pfo_sysvar}

  ;; Initialize output keyword
  count = 0

  ;; Make sure idx exists
  pfo_idx, parinfo, idx

  ;; Indices of any Xin to Xaxis transformations in idx
  return, where(parinfo[idx].pfo.inaxis eq !pfo.Xin and $
                parinfo[idx].pfo.outaxis eq !pfo.Xaxis, count)

end
