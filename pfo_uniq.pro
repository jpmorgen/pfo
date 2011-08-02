;+
; NAME: pfo_uniq
;
; PURPOSE: returns indices of unique elements of an array and
; (optionally) a reverse lookup array of indices that allow grouping
; of the identical elements.
;
; CATEGORY: array manipulation
;
; CALLING SEQUENCE: u_idx = pfo_uniq(array [, sidx][,
; reverse_indices=reverse_indices][, N_uniq=N_uniq])

; DESCRIPTION: pfo_uniq combines characteristics of IDL's uniq and
; histogram routines.  If you just want to find some indices of the
; unique array

; INPUTS:

;	Array:	Input array.  If array is not itself sorted in
;	monotonic order, sidx must be specified

;
; OPTIONAL INPUTS:

;	sidx: the output of sort(array).  Using array and sidx allows
;	pfo_uniq to work without the need to rewrite the input array

;
; KEYWORD PARAMETERS:

;       reverse_indices (output): an array, much like that used by
;       IDL's historgam routine, that allows lookup of groups of
;       identical elements of array

;
; OUTPUTS:

;	array of indices into array of unique elements of that array.
;	If array is sorted monotonically increasing, the last unique
;	element in each set of duplicates is returned.  If the sort is
;	in decreasing order, the first is returned

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
; $Id: pfo_uniq.pro,v 1.1 2011/08/01 19:18:16 jpmorgen Exp $
;
; $Log: pfo_uniq.pro,v $
; Revision 1.1  2011/08/01 19:18:16  jpmorgen
; Initial revision
;
;-
function pfo_uniq, array, sidx, reverse_indices=reverse_indices, N_uniq=N_uniq

  ;; Run the default IDL version if we don't need the reverse_indices.
  ;; Check for the case where we may be recycling reverse_indices
  if N_elements(reverse_indices) eq 0 and $
    NOT arg_present(reverse_indices) then begin
     u_idx = uniq(array, sidx)
     N_uniq = N_elements(u_idx)
     return, u_idx
  endif ;; don't need reverse_indices

  ;; If we made it here, we want to do the reverse_indices

  ;; Make sure we have indices into array
  pfo_idx, array, idx=sidx, N_array=N_array
  ;; sidx provides the indices into array that we need.  Now we just
  ;; need to come up with the indices into sidx that indicate where
  ;; each chunk of duplicates begin and end.  

  ;; Find the uniq indices, referenced to the sorted array.  This cool
  ;; trick with shift and where marks the beginnings and ends of the
  ;; arrays.  Not sure if it is faster to copy off the array or do
  ;; things with indices implicitly.
  su_idx = where(array[sidx] ne array[shift(sidx, -1)], N_uniq)

  ;; Handle case where all elements are identical
  if N_uniq eq 0 then begin
     N_uniq = 1
     su_idx = N_array-1
     retval = su_idx
  endif ;; all identical

  ;; Build reverse_indices a la IDL's histogram function

  ;; First write down the reverse_indices reference section in plain
  ;; idx.  The su_idx give the indices (into the sorted array) of the
  ;; last occurrence of a group of identical elements.  This would be
  ;; the upper boundary of a "bin" in the histogram reverse_indices
  ;; sense.  Make it a true upper boundary and add one to it and make
  ;; sure the ultimate lower boundary (0) is included
  reverse_indices = [0, su_idx+1]
  ;; Now add an offset to deal with the fact that the indices into
  ;; array are going to be appended to this reference section
  reverse_indices += N_elements(reverse_indices)
  ;; Now put on our sorted array indices.  These point into array,
  ;; which we want, but are sorted, which naturally groups identical
  ;; elements together.
  pfo_array_append, reverse_indices, sidx

  if keyword_set(retval) then $
    return, retval

  return, sidx[su_idx]

end
