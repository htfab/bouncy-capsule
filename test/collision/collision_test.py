import cocotb
from cocotb.triggers import Timer

import itertools

splits = [(3, 0, 0), (2, 1, 0), (2, 0, 1), (1, 2, 0), (1, 1, 1), (1, 0, 2), (0, 3, 0), (0, 2, 1), (0, 1, 2), (0, 0, 3)]
signals = ('ds', 'dm', 'vs', 'vm', 'ws', 'wm', 'vnc', 'wnc', 'ign', 'rxc', 'vxc', 'wxc', 'bz', 'vwm', 'vmn', 'wmn', 'vsn', 'wsn', 'vn', 'wn', 'vxn', 'vyn', 'vxt', 'vyt', 'wt', 'impact')


def collision_response(vs, v, ws, w, phi, rd):
    d = [1, 0, 0, 1][phi % 4]
    ds = [0, 0, 1, 1][phi % 4]

    if (ws^ds if (d and ((v == 0 and w >= 1) or (v == 1 and w >= 3))) else vs):
        return (vs, v, ws, w, 0)

    if ds ^ vs ^ ws:
        if d and w == 0 and v >= 2:
            wn = v - 2
            vn = 1
        else:
            wn = max(v + w - 1, 0)
            vn = 0
    else:
        if d and v == 0 and w >= 2:
            vn = w - 2
            wn = 1
        else:
            vn = max(v + w - 1, 0)
            wn = 0

    vns = ws^ds^1 if (d or ((v == 0 and w >= 1) or (v == 1 and w >= 3))) else vs^1
    wns = vs^ds^1 if (d or ((w == 0 and v >= 1) or (w == 1 and v >= 3))) else ws
    if v > 0 or w > 0:
        wn += rd
        vn += 1-rd
    impact = 2*(v+w) + 1

    return (vns, vn, wns, wn, impact)


@cocotb.test()
async def collision_test(dut):

    async def delay():
        await Timer(1, units='ns')

    async def tick():
        dut.clk.value = 0
        await delay()
        dut.clk.value = 1
        await delay()

    async def init():
        dut.clk.value = 0
        dut.rst.value = 1
        dut.update.value = 0
        dut.rotate.value = 0
        dut.mirror.value = 0
        dut.init_vx.value = 2
        dut.init_vy.value = 1
        dut.init_w.value = 0
        dut.phi.value = 1
        dut.round_dir.value = 0
        await tick()
        dut.rst.value = 0
        await tick()

    async def testcase(rot, mir, vxs, vx, vys, vy, ws, w, phi, rd):
        dut.init_vx.value = vxs << 2 | vx
        dut.init_vy.value = vys << 2 | vy
        dut.init_w.value = ws << 2 | w
        dut.rst.value = 1
        await tick()
        dut.rst.value = 0
        await tick()
        dut.update.value = 1
        dut.rotate.value = rot
        dut.mirror.value = mir
        dut.phi.value = phi
        dut.round_dir.value = rd
        await delay()
        sig = {name: dut._id(name, extended=False).value for name in signals}
        impact = int(dut.impact.value)
        await tick()
        dut.update.value = 0
        await tick()
        vxt = int(dut.vxt.value)
        vyt = int(dut.vyt.value)
        wt = int(dut.wt.value)
        qmap = {8: (0, 0), 14: (0, 1), 18: (0, 2), 21: (0, 3), 56: (1, 0), 50: (1, 1), 46: (1, 2), 43: (1, 3)}
        vxos, vxo = qmap[vxt]
        vyos, vyo = qmap[vyt]
        wos, wo = qmap[wt]
        return (vxos, vxo, vyos, vyo, wos, wo, impact, sig)

    await init()

    logmap = {}
    submap = {}
    for run in range(10):
        for vx, vy, w in splits:
            for vxs, vys, ws, rot, mir, rd in itertools.product(range(2), repeat=6):
                for phi in range(4):
                    params = (rot, mir, vxs, vx, vys, vy, ws, w, phi, rd)
                    *outputs, sig = await testcase(*params)
                    outputs = tuple(outputs)
                    if params in logmap:
                        assert logmap[params] == outputs
                    else:
                        logmap[params] = outputs
                        vxos, vxo, vyos, vyo, wos, wo, impact = outputs
                        vs = (1-vxs if mir else vxs) if rot else (1-vys if mir else vys)
                        v = vx if rot else vy
                        phr = (phi + 2) % 4 if rot else phi
                        vos = (1-vxos if mir else vxos) if rot else (1-vyos if mir else vyos)
                        vo = vxo if rot else vyo
                        subparams = (vs, v, ws, w, phr, rd)
                        suboutputs = (vos, vo, wos, wo, impact)
                        if subparams in submap:
                            assert submap[subparams] == suboutputs
                        else:
                            submap[subparams] = suboutputs
                            target = collision_response(*subparams)
                            if vo + wo != v + w or suboutputs != target:
                                print(subparams, '=>', suboutputs, flush=True)
                                print(params, '=>', outputs, flush=True)
                                for name, value in sig.items():
                                    print(name, ':', value, flush=True)
                            assert vo + wo == v + w
                            assert suboutputs == target

