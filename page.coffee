


#
# SETUP HOUSEKEEPING
#
# Following bit of code is setting up the global variables
# and rendering information
#

renderPage = ->
    # renderPage: Populates the webform with labels + boxes
    @vars =
        TELESCOPE:
            tdiam:
                name: "Telescope diameter [m]"
                default: 10
            tfratio:
                name: "Telescope focal ratio []"
                default: 15
            tefl:
                name: "Telescope focal length [m]"
            tscale:
                name: "Telescope plate scale [mm/as]"
        COLLIMATOR:
            beam:
                name: "Beam diameter [mm]"
                default: 141
            slitwidth:
                name: "Slit width [as]"
                default: 1
            slitlength:
                name: "FFOV [arcmin] (~ slit length)"
                default: .1
            slitlengthmm:
                name: "FFOV [mm] (~ slit length)"
            cf:
                name: "Collimator focal length [mm]"
            beamFFOV:
                name: "Beam FFOV [&deg;]"
            dthetaw:
                name: "dtheta<sub>slit width</sub> [radian]"

        DISPERSER:
            density:
                name: "Ruling density [lines/mm]"
                default: 1
            order:
                name: "Grating order []"
                default: 1
            l0:
                name: "&lambda;<sub>center</sub> [&#8491;]"
                default: 5000
            lstart:
                name: "&lambda;<sub>start</sub> [&#8491;]"
            lend:
                name: "&lambda;<sub>end</sub> [&#8491;]"
            dlambda:
                name: "d&lambda;<sub>slit width</sub> [&#8491;]"
            R:
                name: "Resolution [&lambda;<sub>center</sub>/d&lambda;<sub>slit width</sub>]"
            NR:
                name: "Number of resolution elements []"
            grotate:
                name: "Grating Rotation [&deg;]"
                default: 22
            dFFOV:
                name: "Dispersed ffov [&deg;]"

            pr:
                name: "Minimum pupil relief [mm]"
            anamorph:
                name: "Anamorphic factor []"
        CAMERA:
            cFFOV:
                name: "Camera ffov [&deg;]"
            fnum:
                name: "Camera filled f/# []"
                default: 2.0
            camefl:
                name: "Camera focal length [mm]"
            mfnum:
                name: "Camera underfilled f/# []"
            cslitwidth:
                name: "Camera delivered slit width [&mu;m]"
            speclen:
                name: "Spectrum length [mm]"
        DETECTOR:
            pixelsize:
                name: "Pixel size [&mu;m]"
                default: 15
            dslitwidth:
                name: "Slit width [pix]"
            speclenpix:
                name: "Spectrum length [pix]"
            pixwidth:
                name: "Pixel width [as]"
            pixheight:
                name: "Pixel height [as]"
        SYSTEM:
            effarea:
                name: "Effective area (assume 30% thpt) [cm<sup>2</sup>]"
            pixarea:
                name: "Pixel area [as<sup>2</sup>]"
            bandwidth:
                name: "Bandwidth/pixel [&#8491;]"
            pthpt:
                name: "Pixel system throughput [as<sup>2</sup> cm<sup>2</sup> &#8491;]"
            


    form = $("#frmMain")

    addToForm = (container, varname) ->
        form.append('<label title="' + tooltips[varname] + '">' + container[varname].name + " (" + varname + ")</label>")
        form.append('<input type="text" id="' + varname + '"></input><br/>')
        if container[varname].default?
            $("#" + varname)[0].value = container[varname].default

    addHeaderToForm = (name) ->
        form.append("<h2>" + name + "</h2>")

        addToForm vars[name], objname for objname in Object.keys(vars[name])

    @tooltips = solversToTooltips()


    addHeaderToForm name for name in Object.keys(vars)


@drawSpectrograph = () ->

    c = $("#drawArea")[0]

    cf = $("#cf")[0].value
    scale = c.width*.9/(2*cf)

    cf = cf*scale
    cfno = $("#tfratio")[0].value
    slitlen = $("#slitlength")[0].value/60*cf
    beam = $("#beam")[0].value * scale
    pr = $("#pr")[0].value * scale

    grotate = $("#grotate")[0].value
    camfov = $("#cFFOV")[0].value


    console.log scale
    ctx = c.getContext("2d")
    ctx.clearRect(0, 0, c.width, c.height)

    margin = 25
    drawCone = (start, delt, height) ->
        ctx.beginPath()
        ctx.moveTo(start[0], start[1])
        ctx.lineTo(start[0] + delt[0], start[1] + delt[1] + height/2)
        ctx.moveTo(start[0], start[1])
        ctx.lineTo(start[0] + delt[0], start[1] + delt[1] - height/2)
        ctx.stroke()

    drawBeam= (start, efl, diam) ->
        ctx.beginPath()
        ctx.moveTo(start[0], start[1] + diam/2)
        ctx.lineTo(start[0] + efl, originY+diam/2)
        ctx.moveTo(start[0], start[1] - diam/2)
        ctx.lineTo(start[0] + efl, originY-diam/2)
        ctx.stroke()


    ctx.beginPath()
    ctx.lineWidth = .5
    originY = margin+slitlen/2
    ctx.lineTo(margin, margin)
    ctx.lineTo(margin, margin+slitlen)
    ctx.stroke()

    ctx.beginPath()
    ctx.lineWidth = .1
    ctx.moveTo(0, originY)
    ctx.lineTo(400, originY)
    ctx.stroke()

    ctx.lineWidth = 1
    dx =  cf
    dy = dx/cfno
    drawCone([margin, originY], [dx, 0],  dy)
    drawBeam([margin+dx, originY-slitlen/2], dx, beam)

    drawCone([margin, margin], [dx, 0],  dy)
    drawBeam([margin+dx, originY], dx, beam)

    drawCone([margin, margin+slitlen], [dx, 0],  dy)
    drawBeam([margin+dx, margin+slitlen], dx, beam)


# Draw the grating

    tanTilt = Math.tan(grotate/57.3)
    gOrig = [margin+2*dx, originY]
    ctx.beginPath()
    ctx.moveTo(gOrig[0], gOrig[1])
    ctx.lineTo(gOrig[0]-tanTilt*beam/2, gOrig[1]-beam/2*anamorph)
    ctx.lineTo(gOrig[0]+tanTilt*beam/2, gOrig[1]+beam/2*anamorph)
    ctx.stroke()


    drawCamField = (angle) ->
        offX = beam/2*Math.sin(angle/57.3)
        dX = pr*Math.cos(angle/57.3)
        dY = pr*Math.sin(angle/57.3)
        ctx.beginPath()
        ctx.moveTo(gOrig[0]-offX, gOrig[1]+beam/2)
        ctx.lineTo(gOrig[0]-dX-offX, gOrig[1]-dY+beam/2)
        ctx.moveTo(gOrig[0]+offX, gOrig[1]-beam/2)
        ctx.lineTo(gOrig[0]-dX+offX, gOrig[1]-dY-beam/2)
        ctx.stroke()

    aZ = grotate*2
    drawCamField(-aZ+camfov/2)
    drawCamField(-aZ)
    drawCamField(-aZ-camfov)
#
# PHYSICS
#

@solvers =
    telescopeSolver : new Solver
       tdiam: 'tdiam'
       tfratio: 'tscale*206265/1000/tdiam'
       tscale: 'tdiam * tfratio / 206265. * 1000.0'
       tefl: 'tscale*206265/1000'
    collimatorSolver : new Solver
        beam: 'beam'
        cf: 'tfratio * beam'
        slitlength: 'slitlength'
        slitlengthmm: 'beamFFOV/57.3*cf'
        slitwidth: 'slitwidth'
        beamFFOV: 'tdiam/(beam/1000.) * slitlength/60.'
        dthetaw: 'slitwidth * tscale / cf'
    disperserSolver: new Solver
        dthetaw: 'dthetaw'
        order: 'order'
        density: 'density'
        l0: 'l0'
        lstart: 'l0-l0/(order+1)'
        lend: 'l0+l0/(order+1)'
        dlambda: 'dthetaw/(order*density*1e-7)/anamorph'
        R: 'l0/dlambda'
        NR: '(lend-lstart)/dlambda'
        dFFOV: 'NR*dthetaw*57.3'
        grotate: 'grotate'
        pr: '(anamorph*beam/2)/Math.tan((-beamFFOV - dFFOV/2 + 2*grotate)/(2*57.3))'
        anamorph: '1/Math.cos(2*grotate/57.3)'
    cameraSolver: new Solver
        cFFOV: 'Math.sqrt(dFFOV*dFFOV + beamFFOV * beamFFOV)'
        fnum: 'fnum'
        camefl: 'fnum*beam'
        mfnum: '(beam + 2*pr*Math.tan(cFFOV/(2*57.3)))/camefl'
        cslitwidth: 'camefl*dthetaw*1000/anamorph'
        speclen: 'Math.tan(dFFOV/57.3/2)*2*camefl'
    detectorSolver: new Solver
        pixelsize: 'pixelsize'
        dslitwidth: 'cslitwidth/pixelsize'
        speclenpix: 'speclen/(pixelsize/1000)'
        pixwidth: '1/dslitwidth'
        pixheight: 'anamorph/dslitwidth'
    systemSolver: new Solver
        effarea: '0.3*3.14*Math.pow(tdiam/2*.8, 2)*1e4'
        pixarea: 'pixwidth * pixheight'
        bandwidth: 'dlambda/dslitwidth'
        pthpt: 'pixarea*effarea*bandwidth'

#
# DOM Housekeeping
#
@toList = (varElement) ->
    return Object.keys(varElement)

@solversToTooltips = () ->

    tooltips = {}
    console.log(solvers)

    for solvername in Object.keys(solvers)
        solver = solvers[solvername]
        eqs = Object.keys(solver.equations)
        for eq in eqs
            tooltips[eq] = solver.equations[eq]
    
    return tooltips

@bundleVariablesFromDOM = () ->

    popVars = {}

    for varElement in toList(vars)
        allVars = toList(vars[varElement])
        for el in allVars
            value = $("#" + el)[0].value
            flt = parseFloat(value)
            if value != "" and !isNaN(flt)
                popVars[el] = parseFloat(flt)

    return popVars

@populateForm = (solution) ->
    vars = Object.keys(solution)

    for el in vars
        $("#" + el)[0].value = solution[el]


@handleSolve = () ->

    bundle = bundleVariablesFromDOM vars
    console.log(bundle)

    solution = solvers.telescopeSolver.solve(bundle)
    populateForm(solution)

    solution = solvers.collimatorSolver.solve(bundle)
    populateForm(solution)

    solution = solvers.disperserSolver.solve(bundle)
    populateForm(solution)

    solution = solvers.cameraSolver.solve(bundle)
    populateForm(solution)

    solution = solvers.detectorSolver.solve(bundle)
    populateForm(solution)

    solution = solvers.systemSolver.solve(bundle)
    populateForm(solution)

@doSolve = () ->
    handleSolve()
    handleSolve()
    handleSolve()
    handleSolve()
    handleSolve()
    handleSolve()
    handleSolve()
    drawSpectrograph()

button = $("#handleSolve")
button.onclick = handleSolve

renderPage()

