(function(){
  window.setTimeout(function() {
    document.querySelectorAll("svg").forEach(svgZoom);
  },1000);

  function svgZoom(svgContainer) {
    let panX = 0;
    let panY = 0;
    let scale = 1;

    let isDragging = false;
    let startX, startY;

    svgContainer.addEventListener('mousedown', function (e) {
        isDragging = true;
        startX = e.clientX - panX;
        startY = e.clientY - panY;
        svgContainer.style.cursor = 'grabbing';
    });

    svgContainer.addEventListener('mousemove', function (e) {
        if (isDragging) {
            panX = e.clientX - startX;
            panY = e.clientY - startY;
            updateTransform();
        }
    });

    svgContainer.addEventListener('mouseup', function () {
        isDragging = false;
        svgContainer.style.cursor = 'grab';
    });

    svgContainer.addEventListener('wheel', function (e) {
        e.preventDefault();
        const zoomAmount = 1.05;
        if (e.deltaY < 0) {
            scale *= zoomAmount;
        } else {
            scale /= zoomAmount;
        }
      updateTransform();
    });

    function updateTransform() {
      svgContainer.style.transform = `translate(${panX}px, ${panY}px) scale(${scale})`;
    }
    
  }
})();
