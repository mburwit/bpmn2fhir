<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:bpmn2="http://www.omg.org/spec/BPMN/20100524/MODEL"
                xmlns:cp="http://www.helict.de/bpmn4cp"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:fn="internal_functions"
                version="2.0">
    <xsl:output method="xml" indent="yes"/>

    <!-- Entry point -->
    <xsl:template match="/*">
        <xsl:element name="PlanDefinition">
            <xsl:apply-templates select="./bpmn2:process"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="bpmn2:process">
        <xsl:apply-templates select="./bpmn2:subProcess | ./bpmn2:task"/>
    </xsl:template>

    <!-- bpmn2:task | bpmn2:subProcess -->
    <xsl:template match="bpmn2:subProcess | bpmn2:task">
        <xsl:variable name="id" select="@id"/>
        <xsl:element name="action">
            <!-- id -->
            <xsl:call-template name="id">
                <xsl:with-param name="id" select="@id"/>
            </xsl:call-template>
            <!-- title -->
            <xsl:call-template name="title">
                <xsl:with-param name="title" select="@name"/>
            </xsl:call-template>
            <!-- description -->
            <xsl:call-template name="description">
                <xsl:with-param name="description" select="bpmn2:documentation"/>
            </xsl:call-template>
            <!-- code -->
            <xsl:call-template name="codes">
                <xsl:with-param name="codes" select="@cp:code"/>
            </xsl:call-template>
            <!-- related actions -->
            <xsl:call-template name="relatedActions">
                <xsl:with-param name="action" select="current()"/>
            </xsl:call-template>
            <!-- conditional events -->
            <xsl:apply-templates select="fn:getConditionalEvents(//bpmn2:definitions, current())">
                <xsl:with-param name="actionId" select="$id"/>
            </xsl:apply-templates>
            <!-- timing -->
            <xsl:call-template name="timing">
                <xsl:with-param name="action" select="current()"/>
            </xsl:call-template>
            <!-- goals -->
            <xsl:call-template name="goals">
                <xsl:with-param name="action" select="current()"/>
            </xsl:call-template>
            <!-- TODO: evaluate attached boundary events -->
            <!-- only for subProcess... -->
            <xsl:if test="./name()='bpmn2:subProcess'">
                <!-- sub actions - only for subProcess -->
                <xsl:apply-templates select="./bpmn2:subProcess | ./bpmn2:task"/>
                <!-- groupingBehavior of sub actions -->
                <xsl:call-template name="grouping-behavior">
                    <!-- TODO: define how to get the grouping behavior (default: logical-group)
                    <xsl:with-param name="behaviour" select="..."/>
                    -->
                </xsl:call-template>
                <!-- selectionBehavior of sub actions -->
                <xsl:call-template name="selection-behavior">
                    <xsl:with-param name="behaviour" select="@cp:selectionBehavior"/>
                </xsl:call-template>
                <!-- canonical definition -->
                <xsl:call-template name="canonical-definition">
                    <xsl:with-param name="definition" select="@cp:definitionCanonical"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <!-- TODO: check the conversion if BPMN extension finished -->
    <xsl:template match="code">
        <xsl:element name="code">
            <xsl:element name="text">
                <xsl:value-of select="@value"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="bpmn2:startEvent | bpmn2:boundaryEvent | bpmn2:intermediateCatchEvent">
        <xsl:param name="actionId"/>
        <!-- conditional event -->
        <xsl:apply-templates select="bpmn2:conditionalEventDefinition">
            <xsl:with-param name="actionId" select="$actionId"/>
        </xsl:apply-templates>
        <!-- timer event -->
        <xsl:apply-templates select="bpmn2:timerEventDefinition">
            <xsl:with-param name="actionId" select="$actionId"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="bpmn2:conditionalEventDefinition">
        <xsl:param name="actionId"/>
        <xsl:choose>
            <!-- attached conditional event -->
            <xsl:when test="../@attachedToRef=$actionId">
                <!-- ignore non-interrupting events -->
                <xsl:if test="not(../@cancelActivity='false')">
                    <!-- TODO -> stop condition -->
                    <xsl:call-template name="condition">
                        <xsl:with-param name="kind" select="'stop'"/>
                        <xsl:with-param name="expression" select="../@name"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:when>
            <!-- not attached - start condition -->
            <xsl:otherwise>
                <!-- TODO -> applicability condition -->
                <xsl:call-template name="condition">
                    <xsl:with-param name="kind" select="'applicability'"/>
                    <xsl:with-param name="expression" select="../@name"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="condition">
        <xsl:param name="kind"/>
        <xsl:param name="expression"/>
        <!-- create condition element -->
        <xsl:element name="condition">
            <xsl:element name="kind">
                <xsl:attribute name="value">
                    <xsl:value-of select="$kind"/>
                </xsl:attribute>
            </xsl:element>
            <xsl:element name="expression">
                <!-- TODO: find a consensus how to express the conditions (currently: text/cql with the value specified in event/@name) -->
                <xsl:element name="language">
                    <xsl:attribute name="value">text/cql</xsl:attribute>
                </xsl:element>
                <xsl:element name="expression">
                    <xsl:attribute name="value">
                        <xsl:value-of select="$expression"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="bpmn2:timerEventDefinition">
        <xsl:if test="@timeEvent">
            <xsl:element name="event">
                <xsl:attribute name="value">
                    <xsl:value-of select="@timeEvent"/>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template
            match="bpmn2:timeCycle | bpmn2:timeDuration | cp:boundsDuration | cp:boundsRangeLowerLimit | cp:boundsRangeUpperLimit | cp:boundsPeriod">
        <!-- Caution: If more than one cycle timer event is attached or connected with an action, this might here
        lead to more than one element of the repeat elements in FHIR, which is not allowed by FHIR spec. -->
        <xsl:for-each select="@* except @xsi:type except @timeOfDay except @dayOfWeek">
            <xsl:element name="{name()}">
                <xsl:attribute name="value">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:element>
        </xsl:for-each>
        <!-- timeOfDay -->
        <xsl:if test="@timeOfDay">
            <xsl:call-template name="timeOfDay">
                <xsl:with-param name="timesOfDay" select="@timeOfDay"/>
            </xsl:call-template>
        </xsl:if>
        <!-- dayOfWeek -->
        <xsl:if test="@dayOfWeek">
            <xsl:call-template name="dayOfWeek">
                <xsl:with-param name="daysOfWeek" select="@dayOfWeek"/>
            </xsl:call-template>
        </xsl:if>
        <!-- bounds -->
        <xsl:if test="cp:boundsDuration">
            <xsl:element name="boundsDuration">
                <xsl:apply-templates select="cp:boundsDuration"/>
            </xsl:element>
        </xsl:if>
        <xsl:if test="cp:boundsPeriod">
            <xsl:element name="boundsPeriod">
                <xsl:apply-templates select="cp:boundsPeriod"/>
            </xsl:element>
        </xsl:if>
        <xsl:if test="cp:boundsRange">
            <xsl:element name="boundsRange">
                <xsl:if test="cp:boundsRange/cp:boundsRangeLowerLimit">
                    <xsl:element name="low">
                        <xsl:apply-templates select="cp:boundsRange/cp:boundsRangeLowerLimit"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="cp:boundsRange/cp:boundsRangeUpperLimit">
                    <xsl:element name="high">
                        <xsl:apply-templates select="cp:boundsRange/cp:boundsRangeUpperLimit"/>
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    <!--
    Named Templates
    -->

    <xsl:template name="id">
        <xsl:param name="id"/>
        <xsl:attribute name="id">
            <xsl:value-of select="$id"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template name="title">
        <xsl:param name="title"/>
        <xsl:element name="title">
            <xsl:attribute name="value">
                <xsl:value-of select="$title"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template name="codes">
        <xsl:param name="codes"/>
        <xsl:for-each select="tokenize($codes,',')">
            <xsl:element name="code">
                <xsl:element name="text">
                    <xsl:attribute name="value">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="description">
        <xsl:param name="description"/>
        <xsl:if test="$description">
            <xsl:element name="description">
                <xsl:attribute name="value">
                    <xsl:value-of select="$description"/>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template name="canonical-definition">
        <xsl:param name="definition">undefined</xsl:param>
        <xsl:element name="definitionCanonical">
            <xsl:attribute name="value">
                <xsl:value-of select="$definition"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template name="selection-behavior">
        <xsl:param name="behaviour">any</xsl:param>
        <xsl:element name="selectionBehavior">
            <xsl:attribute name="value">
                <xsl:value-of select="$behaviour"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template name="grouping-behavior">
        <xsl:param name="behaviour">logical-group</xsl:param>
        <xsl:element name="groupingBehavior">
            <xsl:attribute name="value">
                <xsl:value-of select="$behaviour"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template name="timeOfDay">
        <xsl:param name="timesOfDay"/>
        <xsl:for-each select="tokenize($timesOfDay,'\|')">
            <xsl:if test="string-length(.) > 0">
                <xsl:element name="timeOfDay">
                    <xsl:attribute name="value">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="dayOfWeek">
        <xsl:param name="daysOfWeek"/>
        <xsl:for-each select="tokenize($daysOfWeek,'\|')">
            <xsl:if test="string-length(.) > 0">
                <xsl:element name="dayOfWeek">
                    <xsl:attribute name="value">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="relatedActions">
        <xsl:param name="action"/>
        <xsl:if test="$action">
            <xsl:for-each select="distinct-values(fn:getAfterEndActions(//bpmn2:definitions, $action)/@id)">
                <xsl:call-template name="relatedAction">
                    <xsl:with-param name="relatedActionId" select="current()"/>
                    <xsl:with-param name="relation">after-end</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="distinct-values(fn:getSuccessors(//bpmn2:definitions, $action)/@id)">
                <xsl:call-template name="relatedAction">
                    <xsl:with-param name="relatedActionId" select="current()"/>
                    <xsl:with-param name="relation">before-start</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="distinct-values(fn:getConcurrentPredecessors(//bpmn2:definitions, $action)/@id)">
                <xsl:call-template name="relatedAction">
                    <xsl:with-param name="relatedActionId" select="current()"/>
                    <xsl:with-param name="relation">concurrent</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="distinct-values(fn:getConcurrentSuccessors(//bpmn2:definitions, $action)/@id)">
                <xsl:call-template name="relatedAction">
                    <xsl:with-param name="relatedActionId" select="current()"/>
                    <xsl:with-param name="relation">concurrent</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>

        </xsl:if>
    </xsl:template>

    <xsl:template name="relatedAction">
        <xsl:param name="relatedActionId"/>
        <xsl:param name="relation"/>
        <xsl:element name="relatedAction">
            <xsl:element name="actionId">
                <xsl:attribute name="value">
                    <xsl:value-of select="$relatedActionId"/>
                </xsl:attribute>
            </xsl:element>
            <xsl:element name="relationship">
                <xsl:attribute name="value">
                    <xsl:value-of select="$relation"/>
                </xsl:attribute>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template name="timing">
        <xsl:param name="action"/>
        <xsl:if test="$action">
            <xsl:variable name="timerDefinitions" select="fn:getTimerEvents(//bpmn2:definitions, $action)"/>
            <xsl:if test="count($timerDefinitions)>0">
                <xsl:element name="timingTiming">
                    <xsl:apply-templates select="$timerDefinitions[bpmn2:timerEventDefinition/@timeEvent]"/>
                    <xsl:if test="count($timerDefinitions except $timerDefinitions[bpmn2:timerEventDefinition/@timeEvent])>0">
                        <xsl:element name="repeat">
                            <xsl:apply-templates
                                    select="$timerDefinitions except $timerDefinitions[bpmn2:timerEventDefinition/@timeEvent]"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template name="goals">
        <xsl:param name="action"/>
        <xsl:if test="$action">
            <xsl:variable name="goalStates" select="fn:getGoalStatesForAction(//bpmn2:definitions, $action)"/>
            <xsl:if test="count($goalStates)>0">
                <xsl:element name="extension">
                    <xsl:attribute name="url">http://www.helict.de/fhir/StructureDefinition/Extension/ActionGoals</xsl:attribute>
                    <xsl:apply-templates select="$goalStates"/>
                </xsl:element>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- template for a single goal using extensions
    <xsl:sequence
                select="for $goalState in $goalStates return $goalState/bpmn2:extensionElements/cp:goal"/>-->
    <xsl:template match="cp:goalState">
        <xsl:element name="extension">
            <xsl:attribute name="url">goal</xsl:attribute>
            <xsl:element name="extension">
                <xsl:attribute name="url">description</xsl:attribute>
                <xsl:element name="valueCodeableConcept">
                    <xsl:element name="text">
                        <xsl:attribute name="value">
                            <xsl:value-of select="@bpmn2:name"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
            <xsl:for-each select="bpmn2:extensionElements/cp:goal">
                <xsl:element name="extension">
                    <xsl:attribute name="url">target</xsl:attribute>
                    <xsl:element name="extension">
                        <xsl:attribute name="url">measure</xsl:attribute>
                        <xsl:element name="valueCodeableConcept">
                            <xsl:element name="coding">
                                <xsl:element name="system">
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="@codeSystem"/>
                                    </xsl:attribute>
                                </xsl:element>
                                <xsl:element name="code">
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="@code"/>
                                    </xsl:attribute>
                                </xsl:element>
                                <xsl:element name="display">
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="@name"/>
                                    </xsl:attribute>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                    <xsl:if test="@defaultValue">
                        <xsl:element name="extension">
                            <xsl:attribute name="url">detail</xsl:attribute>
                            <xsl:element name="valueCodeableConcept">
                                <xsl:element name="text">
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="@defaultValue"/>
                                    </xsl:attribute>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <!--
    Functions
    -->
    <!-- Searches for previous actions of an element. It identifies all relevant direct predecessors of the flow node
    and uses getThisOrPreviousActions() to get the predecessor itself or further search for transitive predecessors.-->
    <xsl:function name="fn:getAfterEndActions" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <!-- a direct predecessor is
        - the source node of an incoming sequenceFlow (if it is not a non-interrupting event)
        - the node that this flowNode is attachedTo (action/sub-process of an attached event)
        -->
        <xsl:variable name="directPredecessors" as="element()*"
                      select="$root//*[@id=$root//bpmn2:sequenceFlow[@targetRef=$flowNode/@id]/@sourceRef and not(@cancelActivity='false')]
                              union $root//*[@id=$flowNode/@attachedToRef]
"/>
        <xsl:sequence
                select="for $predecessor in $directPredecessors return fn:getThisOrPreviousActions($root, $predecessor)"/>
    </xsl:function>

    <!-- returns the flowNode itself, if it is a task or subprocess.
    If the flowNode is a parallelGateway it calls getPreviousActions to further search for all predecessors.
    If the flowNode is of any other type AND has at most 1 incoming sequence flow, it searches for its predecessor.
     Otherwise it stops searching for predecessors -->
    <xsl:function name="fn:getThisOrPreviousActions" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <xsl:choose>
            <xsl:when test="name($flowNode)='bpmn2:subProcess' or name($flowNode)='bpmn2:task'">
                <xsl:sequence select="$flowNode"/>
            </xsl:when>
            <xsl:when
                    test="(name($flowNode)='bpmn2:parallelGateway') or not(count($root//bpmn2:sequenceFlow[@targetRef=$flowNode/@id]) > 1)">
                <xsl:sequence select="fn:getAfterEndActions($root, $flowNode)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Searches for next actions of an element. It identifies all relevant direct successors of the flow node
    and uses getThisOrNextActions() to get the successor itself or further search for transitive successors.-->
    <xsl:function name="fn:getSuccessors" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <!-- a direct successor is
        - the target node of an outgoing sequenceFlow
        -->
        <xsl:variable name="directSuccessors" as="element()*"
                      select="$root//*[@id=$root//bpmn2:sequenceFlow[@sourceRef=$flowNode/@id]/@targetRef]
"/>
        <xsl:sequence
                select="for $successor in $directSuccessors return fn:getThisOrNextActions($root, $successor)"/>
    </xsl:function>

    <!-- returns the flowNode itself, if it is a task or subprocess.
    If the flowNode is a parallelGateway it calls getNextActions to further search for all successors.
    If the flowNode is of any other type AND has at most 1 outgoing sequence flow, it searches for its successors.
     Otherwise it stops searching for successors -->
    <xsl:function name="fn:getThisOrNextActions" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <xsl:choose>
            <xsl:when test="name($flowNode)='bpmn2:subProcess' or name($flowNode)='bpmn2:task'">
                <xsl:sequence select="$flowNode"/>
            </xsl:when>
            <xsl:when
                    test="(name($flowNode)='bpmn2:parallelGateway') or not(count($root//bpmn2:sequenceFlow[@sourceRef=$flowNode/@id]) > 1)">
                <xsl:sequence select="fn:getSuccessors($root, $flowNode)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Searches for previous actions of an element that are concurrent actions, i.e. where the source of the sequence
    flow is a non-interrupting event-->
    <xsl:function name="fn:getConcurrentPredecessors" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <!-- a direct predecessor is
        - the source node of an incoming sequenceFlow
        -->
        <xsl:variable name="directPredecessors" as="element()*"
                      select="$root//*[@id=$root//bpmn2:sequenceFlow[@targetRef=$flowNode/@id]/@sourceRef]"/>
        <xsl:sequence
                select="for $predecessor in $directPredecessors return fn:getAttachedToOrPreviousActions($root, $predecessor)"/>
    </xsl:function>

    <!-- if flowNode is a non-interrupting event, returns the element, where flowNode is attached to.
    If the flowNode is a parallelGateway it calls getConcurrentPredecessors to further search for all predecessors.
    If the flowNode is of any other type AND has at most 1 incoming sequence flow, it searches for its predecessor.
     Otherwise it stops searching for predecessors -->
    <xsl:function name="fn:getAttachedToOrPreviousActions" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <xsl:choose>
            <xsl:when test="$flowNode/@attachedToRef and $flowNode/@cancelActivity='false'">
                <xsl:sequence select="$root//*[@id=$flowNode/@attachedToRef]"/>
            </xsl:when>
            <xsl:when
                    test="(name($flowNode)='bpmn2:parallelGateway') or not(count($root//bpmn2:sequenceFlow[@targetRef=$flowNode/@id]) > 1)">
                <xsl:sequence select="fn:getConcurrentPredecessors($root, $flowNode)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Searches for conditional events of an action or subProcess. This can be an attached event or an event that is
    the source of an incoming sequence flow. The event must have a conditional event definition.  -->
    <xsl:function name="fn:getConcurrentSuccessors" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>
        <xsl:variable name="attachedEvents" as="element()*"
                      select="$root//bpmn2:boundaryEvent[@attachedToRef=$flowNode/@id]
"/>
        <xsl:variable name="directConcurrentSuccessors" as="element()*"
                      select="for $attachedEvent in $attachedEvents
                return $root//*[@id=$root//bpmn2:sequenceFlow[@sourceRef=$attachedEvent/@id]/@targetRef]"/>

        <xsl:sequence
                select="for $directConcurrentSuccessor in $directConcurrentSuccessors return fn:getThisOrNextActions($root, $directConcurrentSuccessor)"/>
    </xsl:function>

    <!-- Searches for conditional events of an action or subProcess. This can be an attached event or an event that is
    the source of an incoming sequence flow. The event must have a conditional event definition.  -->
    <xsl:function name="fn:getConditionalEvents" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>

        <xsl:sequence select="$root//*[@id=$root//bpmn2:sequenceFlow[@targetRef=$flowNode/@id]/@sourceRef and bpmn2:conditionalEventDefinition]
                              union $root//*[@attachedToRef=$flowNode/@id and bpmn2:conditionalEventDefinition]"/>
    </xsl:function>

    <!-- Searches for timer events of an action or subProcess. This can be an attached event or an event that is
    the source of an incoming sequence flow. The event must have a timer event definition.  -->
    <xsl:function name="fn:getTimerEvents" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="flowNode" as="element()"/>

        <xsl:sequence select="$root//*[@id=$root//bpmn2:sequenceFlow[@targetRef=$flowNode/@id]/@sourceRef and bpmn2:timerEventDefinition]
                              union $root//*[@attachedToRef=$flowNode/@id and bpmn2:timerEventDefinition]"/>
    </xsl:function>


    <!--
    Get all goals for an action
    -->
    <xsl:function name="fn:getGoalStatesForAction" as="element()*">
        <xsl:param name="root" as="element()"/>
        <xsl:param name="action" as="element()"/>

        <xsl:sequence select="$root//cp:goalState[@id=$root//bpmn2:association[@sourceRef=$action/@id]/@targetRef]"/>
    </xsl:function>
</xsl:stylesheet>