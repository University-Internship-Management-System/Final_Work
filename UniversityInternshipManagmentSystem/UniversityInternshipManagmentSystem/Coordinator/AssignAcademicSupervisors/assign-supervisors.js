(() => {
    'use strict';
    const review = document.getElementById('assignReviewModal');
    let listScroll = 0;
    function updateReview() {
        const list = document.querySelector('.assign-list-scroll');
        if (list) list.scrollTop = listScroll;
        const open = document.getElementById('openReview');
        if (!open || !window.bootstrap) return;
        const modal = bootstrap.Modal.getOrCreateInstance(review);
        if (open.value === '1') modal.show();
        else modal.hide();
    }
    review.addEventListener('hidden.bs.modal', () => {
        document.getElementById('openReview').value = '0';
    });
    if (window.Sys) {
        Sys.WebForms.PageRequestManager.getInstance().add_beginRequest((sender, args) => {
            const list = document.querySelector('.assign-list-scroll');
            const source = args.get_postBackElement();
            listScroll = source && ['assignMajor', 'assignStatus', 'assignSearch'].includes(source.id)
                ? 0 : list ? list.scrollTop : 0;
        });
        Sys.Application.add_load(updateReview);
    }
    updateReview();
    const saved = document.getElementById('assignSavedModal');
    if (saved && window.bootstrap) bootstrap.Modal.getOrCreateInstance(saved).show();
})();
