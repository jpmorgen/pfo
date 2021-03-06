;+
; NAME: pfo_parinfo_container_cw

; PURPOSE: This is a special compound widget which is used by
; pfo_parinfo_parse.  See DESCRIPTION

; CATEGORY: PFO widgets
;
; CALLING SEQUENCE: ID = pfo_parinfo_container_cw(parentID,
; containerID=containerID, cw_obj=cw_obj, _EXTRA=extra)

; DESCRIPTION: This creates a compound widget with nothing in it.  The
; container is initilized as a column widget, with base_align_left
; set, appropriate for display of parinfo widgets launched from within
; pfo_parinfo_parse.  Since this does create a persistent object on
; the heap (at least until its parent widget is killed), this object
; is the appropriate place from which to repopulate the widget when
; requested.  Repopulation can only occur if this instance of
; pfo_parinfo_container_cw is displaying all of the parinfo array.

; The routine pfo_parinfo_cw_obj::register_repop has a list of
; keywords that invalidate the ability of this widget to repopulate
; itself with the entire contents of the parinfo.  It is therefore
; important to pass all of these keywords to this widget!
; pfo_parinfo_parse should take care of all of this.

; If pfo_parinfo_parse was called by code that selected idx, ispec,
; etc. (the keywords that invalidate the ability of this widget to
; repopulate), then that calling code needs to provide a repopulate
; method.  This repopulate method needs to be intelligent enough to
; independently derive what section of the parinfo should be
; displayed.

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
; $Id: pfo_parinfo_container_cw.pro,v 1.6 2011/11/18 16:09:21 jpmorgen Exp $
;
; $Log: pfo_parinfo_container_cw.pro,v $
; Revision 1.6  2011/11/18 16:09:21  jpmorgen
; Change to calling widget_control on tlb rather than possibly
; non-existent parent
;
; Revision 1.5  2011/09/23 13:08:54  jpmorgen
; Sucessfully using parinfo_edit methods
;
; Revision 1.4  2011/09/22 01:42:35  jpmorgen
; About to delete some commented out code
;
; Revision 1.3  2011/09/16 13:44:47  jpmorgen
; Playing with things that hopefully make the widget system faster
;
; Revision 1.2  2011/09/08 20:15:08  jpmorgen
; Cleaned up/created update of widgets at pfo_parinfo_obj level
;
; Revision 1.1  2011/09/01 22:19:31  jpmorgen
; Initial revision
;
;-

;; Repopulate method for pfo_parinfo_container_cw.  We get called if there is a
;; repopulate and we are just displaying the entire parinfo
pro pfo_parinfo_container_cw_obj::repopulate

  ;;;; --> debugging long time for repopulate
  ;;t1 = systime(/seconds)

  ;; Turn off update in the parent so we don't unnecessarily redraw
  ;; widgets.  Try to unmap the window to see if it goes faster...nope
  widget_control, self.tlbID, update=0
  ;; Kill the container and all its contents.  Each of the children
  ;; should properly issue pfo_obj->unregister_refresh.  This also
  ;; creates a fresh container into which we will draw the new version
  ;; of the widget
  self->clear_container
  ;;print, 'container clear in ', systime(/seconds) - t1

  ;; Call pfo_parinfo_parse to repopulate our container.  In our init
  ;; method, we have intercept the parameters that would have
  ;; invalidated repopulation (e.g. idx, iROI, etc.).  All other
  ;; parameters need to be passed onto our underlying __widget
  ;; routines so that everything ends up getting displayed the way we
  ;; want it.  --> I am currently not allowing for customization of
  ;; widgets to persist across calls to repopulate.  This might be
  ;; possible, but would take some property to keep track of it.
  self.pfo_obj->parinfo_edit, status_mask=!pfo.all_status, $
         containerID=self.containerID, _EXTRA=*self.pextra
  ;;print, 'container repopulated, but not updated in ', systime(/seconds) - t1
  ;; Redraw the parent widget
  widget_control, self.tlbID, update=1

  ;;print, 'Time for pfo_parinfo_container_cw repouplate = ', systime(/seconds) - t1 
end

;; Cleanup method
pro pfo_parinfo_container_cw_obj::cleanup
  ;; Call our inherited cleaup routines
  self->pfo_parinfo_cw_obj::cleanup
end

;; Init method
function pfo_parinfo_container_cw_obj::init, $
   parentID, $ ;; widgetID of parent widget
   _REF_EXTRA=extra ;; All other input parameters are passed to underlying routines via _REF_EXTRA

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

  ;; Call our inherited init routines.  This puts pfo_obj into self,
  ;; among other things
  ok = self->pfo_parinfo_cw_obj::init(parentID, _EXTRA=extra)
  if NOT ok then return, 0

  ;; Register in the repopulate list (if possible)
  self->register_repop, _EXTRA=extra

  ;; We need to create a container here, since we use this for
  ;; repopulate ion.  Make our container as a column base with each
  ;; row left justified.  Subsequent widgets decide how to handle each
  ;; row.
  self->create_container, /column;;, /base_align_left

  ;; If we made it here, we have successfully set up our container.  
  return, 1

end

;; Object class definition
pro pfo_parinfo_container_cw_obj__define
  objectClass = $
     {pfo_parinfo_container_cw_obj, $
      inherits pfo_parinfo_cw_obj}
end


;;-------------------------------------------------------------------
;; MAIN ROUTINE
;;-------------------------------------------------------------------

;; Pattern this on ~/pro/coyote/fsc_field.pro
function pfo_parinfo_container_cw, $
   parentID, $ ;; Parent widget ID (positional parameter)
   containerID=containerID, $ ;; (output) parent widget of individual parinfo function widgets
   cw_obj=cw_obj, $ ;; (output) the object that runs this cw
   _REF_EXTRA=extra ;; All other input parameters passed to the init method and underlying routines via _REF_EXTRA mechanism

  ;; Make sure our system variables are defined for all of the
  ;; routines in this file
  init = {tok_sysvar}
  init = {pfo_sysvar}

  ;; Initialize output
  cwID = !tok.nowhere
  containerID = !tok.nowhere

  ;; Create our controlling object
  cw_obj = pfo_cw_obj_new(parentID, _EXTRA=extra)

  ;; The init method creates the widget and stores its ID in self.tlb.
  ;; Use the getID method to access it.  We return this ID, since that
  ;; is what people expect when they call a widget creation function.
  ;; What people will probably really want is the object to do the
  ;; heavy-duty control.  Default to a nonsense widgetID unless the
  ;; object creation was sucessful.
  if obj_valid(cw_obj) then begin
     cwID = cw_obj->tlbID()
     containerID = cw_obj->containerID()
  endif ;; valid cw_obj

  return, cwID

end
