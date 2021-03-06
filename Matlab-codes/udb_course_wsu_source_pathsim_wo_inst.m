clear all;


%% inputs
DAT_LOC = '/srv/data/projects/apps/RepIndep_CIDR/udb_course';
ANS_LOC = '/srv/data/projects/apps/RepIndep_CIDR/udb_results/course_wsu_source_result';
mkdir(ANS_LOC);

%% inputs
node_files = { [DAT_LOC '/course.txt'], [DAT_LOC '/offer.txt'], [DAT_LOC '/subject.txt']  };
edge_files = { [DAT_LOC '/course_offer.txt'], [DAT_LOC '/offer_subject.txt']};
query_file = [DAT_LOC '/_query.txt'];
answer_loc = ANS_LOC;

label = 'course';
alg = 'pathsim'; metapath = {'course','offer','subject'};
%alg = 'rwr';
%alg = 'simrank';
VERBOSE = 0;

%% settings
[Gs,VG,EG,h_VVG,h_VA,h_VL,h_L] = graphReader(node_files,edge_files);
[QT,QG] = queryReader(query_file,label,h_VA,h_VL,h_VVG,h_L);
LG = h_L(label);
CA = getIndexByType(LG,h_VVG,h_VL); CA = CA{1}; % candidate answers index in G
disp(['Data size is |V|=' num2str(length(VG)) ' |E|=' num2str(length(EG))]);

%% algorithms
tstart = tic;

res_folder = [answer_loc '/' alg];
res_file = [res_folder '/answer.query'];
mkdir(res_folder);

if strcmpi(alg,'pathsim')
    disp('>> running PathSim');
    path = findMetaPathID(metapath,h_L);
    SG = pathSim(Gs,h_VVG,h_VL,path);
    SQ = SG(QG,CA);
    for q = 1:length(QG)
        display(['-- processing "' QT{q} '"']);
        sq = full(SQ(q,:));
        [rnk,gid] = sort(sq,'descend');
        fid = fopen([res_file num2str(q) '.txt'],'w');
        for i = 1:length(gid)
            if QG(q)==CA(gid(i)), continue; end;
            if rnk(i)==0, continue; end;
            fprintf(fid,'%s\t|\t%.8f\n',h_VA(VG(CA(gid(i)))),rnk(i));
            if VERBOSE, fprintf('%s\t|\t%.8f\n',h_VA(VG(CA(gid(i)))),rnk(i)); end;
        end;
        fclose(fid);
    end;
elseif strcmpi(alg,'rwr')
    disp('>>> calculating Random Walk With Restart <<<');
    for q = 1:length(QG)
        display(['-- processing "' QT{q} '"']);
        SQ = RWR(QG(q),Gs,0.8,100);
        sq = full(SQ(CA));
        [rnk,gid] = sort(sq,'descend');
        fid = fopen([res_file num2str(q) '.txt'],'w');
        for i = 1:length(gid)
            if QG(q)==CA(gid(i)), continue; end;
            if rnk(i)==0, continue; end;
            fprintf(fid,'%s\t|\t%.8f\n',h_VA(VG(CA(gid(i)))),rnk(i));
            if VERBOSE, fprintf('%s\t|\t%.8f\n',h_VA(VG(CA(gid(i)))),rnk(i)); end;
        end;
        fclose(fid);
    end;
elseif strcmpi(alg,'simrank')
    disp('>>> calculating SimRank <<<');
    SG = simRank(Gs,0.8,25);
    SQ = SG(QG,CA);
    for q = 1:length(QG)
        display(['-- processing "' QT{q} '"']);
        sq = full(SQ(q,:));
        [rnk,gid] = sort(sq,'descend');
        fid = fopen([res_file num2str(q) '.txt'],'w');
        for i = 1:length(gid)
            if QG(q)==CA(gid(i)), continue; end;
            if rnk(i)==0, continue; end;
            fprintf(fid,'%s\t|\t%.8f\n',h_VA(VG(CA(gid(i)))),rnk(i));
            if VERBOSE, fprintf('%s\t|\t%.8f\n',h_VA(VG(CA(gid(i)))),rnk(i)); end;
        end;
        fclose(fid);
    end;
end;
tend = toc(tstart);
display([alg ': elapsed time = ' num2str(tend)]);
display('---------------------------------------------------------------');

exit;
