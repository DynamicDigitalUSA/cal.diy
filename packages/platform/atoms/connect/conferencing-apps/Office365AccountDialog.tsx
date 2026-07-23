import type { DialogProps as ControlledDialogProps } from "@calcom/features/components/controlled-dialog";
import { Dialog } from "@calcom/features/components/controlled-dialog";
import { Button } from "@calcom/ui/components/button";
import { DialogContent, DialogFooter, DialogClose } from "@calcom/ui/components/dialog";

/** Local copy so slim Docker builds can omit office365video from app-store. */
export function Office365AccountDialog(
  props: ControlledDialogProps & {
    handleSubmit: () => void;
  }
) {
  return (
    <Dialog name="Account check" open={props.open} onOpenChange={props.onOpenChange}>
      <DialogContent
        type="creation"
        title="Connecting with MS Teams requires a work/school Microsoft account."
        description="If you continue with a personal account you will receive an error">
        <DialogFooter showDivider className="mt-6">
          <>
            <DialogClose
              type="button"
              color="secondary"
              tabIndex={-1}
              onClick={() => {
                props.onOpenChange?.(false);
              }}>
              Cancel
            </DialogClose>

            <Button type="button" onClick={props.handleSubmit}>
              Continue
            </Button>
          </>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
