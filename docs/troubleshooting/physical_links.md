# Physical Links

The physical cables or fibers that connect the switches to eachother and to
servers can be monitored with the following commands:

```console
core@control-1 ~ $ kubectl fabric inspect switch --name ds5000-02 --transceivers
NAME         PROFILE             ROLE     GROUPS    SERIAL                    STATE    GEN      APPLIED           HEARTBEAT
ds5000-02    Celestica DS5000    spine              R4028F2B125421GD200304    Ready    55/55    20 minutes ago    6 seconds ago

Transceivers:
NAME     OPER      DESCRIPTION                          CLASS    CONNECTOR       VENDOR     PART                SERIAL           CMIS
E1/1     active    OSFP112 800GBASE-DR8                 FIBER    MPO_2x12        T1NEXUS    T1O112-800G-2DR4    T100AC006346     Ready 4.0 (4)
E1/5     active    OSFP112 2x(400GBASE-CR4-DAC)-2.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-2QPC02    C2504186220      Ready 5.0 (0)
E1/61    active    OSFP112 2x(400GBASE-CR4-DAC)-2.0M    DAC      NO_SEPARABLE    FS         OSFP-800G2OPC015    C2504422334      Ready 5.0 (0)
E1/62    active    OSFP112 2x(400GBASE-CR2-DAC)-1.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-PC01      C2504140951-1    Ready 4.0 (0)
E1/63    active    OSFP112 2x(400GBASE-CR2-DAC)-1.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-PC01      C2504422332-2    Ready 4.0 (0)
E1/64    active    OSFP112 2x(400GBASE-CR2-DAC)-1.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-PC01      C2504422333-1    Ready 4.0 (0)

Use flags for more details: -d/--details (e.g. firmware), -p/--ports, -t/--transceivers, -c/--counters, -l/--lasers
```

The status of the lasers is also available through the inspect commands:

```console
core@control-1 ~ $ kubectl fabric inspect switch --name ds5000-02 --lasers
NAME         PROFILE             ROLE     GROUPS    SERIAL                    STATE    GEN      APPLIED           HEARTBEAT
ds5000-02    Celestica DS5000    spine              R4028F2B125421GD200304    Ready    55/55    21 minutes ago    11 seconds ago

Laser Status:
NAME    CHANNELS IN / OUT ( BIAS )
E1/1    0: 2.61/1.88 dBm (36.56 mA)    1: 1.07/1.72 dBm (36.56 mA)    2: 1.72/1.68 dBm (36.56 mA)    3: 2.38/1.68 dBm (36.56 mA)

Use flags for more details: -d/--details (e.g. firmware), -p/--ports, -t/--transceivers, -c/--counters, -l/--lasers
```
often a value of `-40dBm` on the transmit or receive side indicates that the
laser is not on. If supported check the CMIS status of the optic.

The output of inspect commands can be formatted as: text, json, or yaml.
