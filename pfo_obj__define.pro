;+
; NAME: pfo_obj
;
; PURPOSE: Create the central object in the PFO system
;
; CATEGORY: PFO
;
; CALLING SEQUENCE: pfo_obj = obj_new('pfo_obj', [[Xin,] Yin [Yerr]],
; keywords)
;
; DESCRIPTION:
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
; $Id: pfo_obj__define.pro,v 1.1 2011/08/01 19:18:16 jpmorgen Exp $
;
; $Log: pfo_obj__define.pro,v $
; Revision 1.1  2011/08/01 19:18:16  jpmorgen
; Initial revision
;
;-

;; Each inherited class should have a descr method.
function pfo_obj::descr

  init = {pfo_sysvar}

  ;; Handle pfo_debug level.  CATCH errors if _not_ debugging
  if !pfo.debug le 0 then begin
     CATCH, err
     if err ne 0 then begin
        CATCH, /CANCEL
        message, /NONAME, !error_state.msg, /CONTINUE
        message, 'ERROR: caught the above error.', /CONTINUE
        return, 'Not documented.'
     endif
  endif ;; not debugging

  descr = *self.ppfo_obj_descr
  pfo_struct_append, descr, {pfo_mpfit_obj: self->pfo_mpfit_obj::descr()}
  pfo_struct_append, descr, {pfo_plot_obj: self->pfo_plot_obj::descr()}
  return, descr
end

pro pfo_obj::cleanup
  ptr_free, self.ppfo_obj_descr
  self->pfo_mpfit_obj::cleanup
  self->pfo_plot_obj::cleanup
end

function pfo_obj::init, $
   p0, $	;; Xin or Yin
   p1, $	;; Yin
   p2, $	;; Yerr
   _REF_EXTRA=extra

  init = {pfo_sysvar}
  
  ;; Handle pfo_debug level.  CATCH errors if _not_ debugging
  if !pfo.debug le 0 then begin
     CATCH, err
     if err ne 0 then begin
        CATCH, /CANCEL
        message, /NONAME, !error_state.msg, /CONTINUE
        message, 'ERROR: caught the above error.  Object not properly initialized ', /CONTINUE
        return, 0
     endif
  endif ;; not debugging

  ;; Create our documentation string
  self.ppfo_obj_descr $
     = ptr_new( $
     {README	: 'pfo_obj is the default top-level object of the PFO system', $
      SUPERCLASSES: 'pfo_mpfit_obj, pfo_plot_obj', $
      PROPERTY	: '', $
      METHODS	: ''} $
              )

  ;; Call our superclass init methods
  ok = self->pfo_mpfit_obj::init(p0, p1, p2, _EXTRA=extra)
  if NOT ok then $
     return, 0
     
  return, self->pfo_plot_obj::init(_EXTRA=extra)

end


pro pfo_obj__define
  objectClass = $
     {pfo_obj, $
      ppfo_obj_descr: ptr_new(), $  ;; Pointer to description structure
      inherits pfo_mpfit_obj,  $
      inherits pfo_plot_obj $
      }
end